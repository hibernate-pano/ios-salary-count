import SwiftUI

/// 可分享的「战绩卡」。
///
/// 设计为脱离屏幕环境独立渲染（供 ImageRenderer 截图），
/// 所有数据与主题经参数传入，不依赖 @Environment / @EnvironmentObject。
/// 固定 4:5 竖版比例（1080×1350），适配小红书/微信朋友圈。
struct ShareCardView: View {
    let todayEarnings: Double
    let monthEarnings: Double
    let yearEarnings: Double
    let isWorkday: Bool
    let dateText: String
    let brand: BrandTheme

    /// 渲染基准尺寸（点）。ImageRenderer 再乘 scale 输出高清图。
    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部：标题 + 日期
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isWorkday ? "今日摸鱼战绩" : "本月摸鱼战绩")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(dateText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 32)
            .padding(.horizontal, 28)

            Spacer()

            // 主角：大金额
            VStack(alignment: .leading, spacing: 6) {
                Text(isWorkday ? "今天已经赚到" : "这个月已经赚到")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(formatCurrency(isWorkday ? todayEarnings : monthEarnings))
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
            }
            .padding(.horizontal, 28)

            // 梗
            Text(punchline)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.18), in: Capsule())
                .padding(.horizontal, 28)
                .padding(.top, 14)

            Spacer()

            // 底部：本月/年度小数据 + 水印
            HStack(spacing: 20) {
                miniStat(label: "本月累计", value: monthEarnings)
                miniStat(label: "年度累计", value: yearEarnings)
            }
            .padding(.horizontal, 28)

            Divider()
                .overlay(.white.opacity(0.25))
                .padding(.horizontal, 28)
                .padding(.top, 18)

            HStack(spacing: 6) {
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 14))
                Text("牛马薪水计算器 · 实时看你在赚钱")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(brand.heroGradient(isWorkday: isWorkday))
    }

    private func miniStat(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
            Text(formatCurrency(value))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 摸鱼梗：按金额区间给不同文案，制造分享欲。
    private var punchline: String {
        let amount = isWorkday ? todayEarnings : monthEarnings
        if isWorkday {
            switch amount {
            case ..<50: return "刚开张，钱包正在预热 ☕️"
            case 50..<150: return "稳稳的，每一秒都在涨 📈"
            case 150..<300: return "今天这条鱼摸得有声有色 🐟"
            default: return "老板的钱正在飞向我 💸"
            }
        } else {
            return "这个月的牛马没白当 💪"
        }
    }
}

#Preview {
    ShareCardView(
        todayEarnings: 234.56,
        monthEarnings: 4567.89,
        yearEarnings: 28900.00,
        isWorkday: true,
        dateText: "2026年6月6日",
        brand: .green
    )
}
