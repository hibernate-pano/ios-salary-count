import SwiftUI
import WidgetKit

// MARK: - 共享小件

/// 每秒工资 = 预计今日总额 / 每日工作秒数。
private func perSecond(_ entry: SalaryEntry) -> Double {
    guard entry.totalWorkSeconds > 0 else { return 0 }
    return entry.expectedTodayTotal / entry.totalWorkSeconds
}

/// 金色金额（主角）：¥ 与小数小一号，整数主体大，金色渐变 + 柔和金光。
struct GoldAmount: View {
    let value: Double
    var size: CGFloat = 40

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("¥")
                .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
            Text(integerPart)
                .font(.system(size: size, weight: .heavy, design: .rounded))
            if let dec = decimalPart {
                Text(dec)
                    .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
            }
        }
        .foregroundStyle(Brand.goldGradient)
        .monospacedDigit()
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .shadow(color: Brand.gold.opacity(0.45), radius: 8, y: 0)   // 金光弥散
        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)        // 底部压实，增厚重感
    }

    /// 整数部分（含千分位），如 "286"、"1,203"。
    private var integerPart: String {
        let s = WidgetFormat.currency(value)          // "¥286.50" / "¥1,203"
        let noSign = s.replacingOccurrences(of: "¥", with: "")
        return noSign.split(separator: ".").first.map(String.init) ?? noSign
    }

    /// 小数部分，如 ".50"；无小数返回 nil。
    private var decimalPart: String? {
        let s = WidgetFormat.currency(value)
        let noSign = s.replacingOccurrences(of: "¥", with: "")
        let parts = noSign.split(separator: ".")
        return parts.count > 1 ? "." + parts[1] : nil
    }
}

/// 右上角涨幅/状态徽章。
struct GainBadge: View {
    let entry: SalaryEntry

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8, weight: .black))
            Text(text).font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7).padding(.vertical, 3.5)
        .background(color.opacity(0.16), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 0.5))
    }

    private var icon: String {
        switch entry.state {
        case .working: return "arrow.up.right"
        case .afterWork: return "checkmark"
        case .lunch: return "cup.and.saucer.fill"
        case .beforeWork: return "clock"
        case .dayOff: return "moon.stars.fill"
        }
    }
    private var text: String {
        switch entry.state {
        case .working: return WidgetFormat.percent(entry.progress)
        case .afterWork: return "满勤"
        case .lunch: return "午休"
        case .beforeWork: return "待开工"
        case .dayOff: return "休息"
        }
    }
    private var color: Color {
        switch entry.state {
        case .working: return Brand.gain
        case .afterWork: return Brand.gold
        case .dayOff: return Color(red: 1.0, green: 0.62, blue: 0.30)
        case .lunch, .beforeWork: return Color.white.opacity(0.6)
        }
    }
}

/// 增长提示行「↗ 每秒 +¥X」。仅工作中显示。
struct GrowthHint: View {
    let entry: SalaryEntry
    var body: some View {
        if entry.state == .working {
            HStack(spacing: 3) {
                Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .bold))
                Text("每秒 +¥\(String(format: "%.4f", perSecond(entry)))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(Brand.gain)
        }
    }
}

/// 顶部标签文案。
private func topLabel(_ entry: SalaryEntry) -> String {
    switch entry.state {
    case .dayOff: return "本月已赚"
    case .beforeWork: return "预计今日"
    default: return "今日已赚"
    }
}

/// 主金额：休息日显示本月，上班前显示预计今日，其余显示今日已赚。
private func heroAmount(_ entry: SalaryEntry) -> Double {
    switch entry.state {
    case .dayOff: return entry.monthEarnings
    case .beforeWork: return entry.expectedTodayTotal
    default: return entry.todayEarnings
    }
}

/// 底部辅助文案。
private func footnote(_ entry: SalaryEntry) -> String {
    switch entry.state {
    case .beforeWork: return "上班 \(WidgetFormat.clock(entry.workStart))"
    case .afterWork: return "今日已下班 · 明天见"
    case .dayOff: return "好好休息"
    case .lunch: return "午休中 · 截至 \(WidgetFormat.clock(entry.date))"
    case .working: return "截至 \(WidgetFormat.clock(entry.date))"
    }
}

// MARK: - Small：金额主角 + 涨幅徽章

struct SmallSalaryView: View {
    let entry: SalaryEntry

    var body: some View {
        ZStack {
            // 角落半透明 ¥ 水印
            Text("¥")
                .font(.system(size: 130, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.05))
                .offset(x: 38, y: 30)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(topLabel(entry))
                        .font(.caption2)
                        .foregroundStyle(Brand.gold.opacity(0.9))
                    Spacer()
                    GainBadge(entry: entry)
                }
                Spacer(minLength: 2)
                GoldAmount(value: heroAmount(entry), size: 38)
                Spacer(minLength: 2)
                if entry.state == .working {
                    GrowthHint(entry: entry)
                } else {
                    Text(footnote(entry))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .widgetMoneyBackground()
    }
}

// MARK: - Medium：大金额 + 右侧细节

struct MediumSalaryView: View {
    let entry: SalaryEntry

    var body: some View {
        ZStack {
            Text("¥")
                .font(.system(size: 170, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.05))
                .offset(x: 120, y: 14)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(topLabel(entry))
                        .font(.caption)
                        .foregroundStyle(Brand.gold.opacity(0.9))
                    Spacer()
                    GainBadge(entry: entry)
                }

                Spacer(minLength: 4)
                GoldAmount(value: heroAmount(entry), size: 46)
                Spacer(minLength: 4)

                HStack(spacing: 12) {
                    if entry.state == .working {
                        GrowthHint(entry: entry)
                    } else {
                        Text(footnote(entry))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("本月 \(WidgetFormat.currency(entry.monthEarnings))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .widgetMoneyBackground()
    }
}

// MARK: - Large：今日 hero + 进度 + 本月/年度

struct LargeSalaryView: View {
    let entry: SalaryEntry

    var body: some View {
        ZStack {
            Text("¥")
                .font(.system(size: 240, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.04))
                .offset(x: 90, y: -80)

            VStack(alignment: .leading, spacing: 16) {
                // 今日 hero
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(topLabel(entry))
                            .font(.subheadline)
                            .foregroundStyle(Brand.gold.opacity(0.9))
                        Spacer()
                        GainBadge(entry: entry)
                    }
                    GoldAmount(value: heroAmount(entry), size: 58)
                    if entry.state == .working {
                        GrowthHint(entry: entry)
                    } else {
                        Text(footnote(entry))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                // 进度条（工作日才显示）
                if entry.state != .dayOff {
                    VStack(spacing: 6) {
                        ProgressBar(progress: entry.progress)
                            .frame(height: 8)
                        HStack {
                            Text("\(WidgetFormat.clock(entry.workStart)) 上班")
                            Spacer()
                            Text("预计满勤 \(WidgetFormat.currency(entry.expectedTodayTotal))")
                            Spacer()
                            Text("\(WidgetFormat.clock(entry.workEnd)) 下班")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }

                Divider().overlay(Color.white.opacity(0.15))

                // 本月 / 年度
                HStack(spacing: 16) {
                    StatColumn(title: "本月累计", amount: entry.monthEarnings)
                    StatColumn(title: "年度累计", amount: entry.yearEarnings)
                }

                Spacer(minLength: 0)
                Text("截至 \(WidgetFormat.clock(entry.date)) 更新")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .widgetMoneyBackground()
    }
}

// MARK: - 复用小件

/// 进度条（深底版，金色填充）。
struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(Brand.goldGradient)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
    }
}

/// 本月/年度统计列（深底版）。
struct StatColumn: View {
    let title: String
    let amount: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Text(WidgetFormat.currency(amount))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 未配置引导（深底版）。
struct UnconfiguredView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "yensign.circle.fill")
                .font(.title)
                .foregroundStyle(Brand.gold)
            Text("打开 App 设置工资")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetMoneyBackground()
    }
}

// MARK: - 财富深色背景容器

/// 富质感深色背景：深蓝黑渐变 + 左上金色光晕（让金额发光）+ 顶部高光描边。
struct MoneyBackground: View {
    var body: some View {
        ZStack {
            Brand.widgetDarkBackground
            // 左上金色辉光（钱在「发光」的氛围）
            RadialGradient(
                colors: [Brand.gold.opacity(0.28), Brand.gold.opacity(0.0)],
                center: .init(x: 0.18, y: 0.16),
                startRadius: 2,
                endRadius: 190
            )
            // 右下青绿微光（呼应增长，增加色彩纵深）
            RadialGradient(
                colors: [Brand.gain.opacity(0.12), .clear],
                center: .init(x: 0.92, y: 0.94),
                startRadius: 2,
                endRadius: 150
            )
        }
    }
}

extension View {
    /// 深色财富背景 + 顶部高光内描边 + iOS17+ containerBackground 兼容。
    @ViewBuilder
    func widgetMoneyBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.padding(16)
                .containerBackground(for: .widget) {
                    MoneyBackground().overlay(topHighlight)
                }
        } else {
            self.padding(16)
                .background(MoneyBackground().overlay(topHighlight))
        }
    }

    /// 顶部细高光边，制造「玻璃/金属」质感。
    private var topHighlight: some View {
        LinearGradient(
            colors: [.white.opacity(0.10), .clear],
            startPoint: .top, endPoint: .center
        )
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

