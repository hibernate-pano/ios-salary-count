import SwiftUI

/// 货币格式化（人民币，两位小数）。
private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "CNY"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
}()

func formatCurrency(_ value: Double) -> String {
    currencyFormatter.string(from: NSNumber(value: value)) ?? "¥0.00"
}

/// 每秒工资可能很小（如 ¥0.005），用 4 位小数避免显示成 0。
func formatPerSecond(_ value: Double) -> String {
    String(format: "¥%.4f", value)
}

/// 实时跳动主页。
struct HomeView: View {
    @EnvironmentObject private var store: SalaryStore
    @Environment(\.brand) private var brand

    /// 控制分享卡片 sheet 的展示。
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if store.isHolidayDataMissing {
                        holidayDataBanner
                    }
                    todayHero
                    HStack(spacing: 14) {
                        StatCard(title: "本月累计", icon: "calendar", amount: store.monthEarnings)
                        StatCard(title: "年度累计", icon: "chart.line.uptrend.xyaxis", amount: store.yearEarnings)
                    }
                    YearTargetCard(earned: store.yearEarnings, target: store.yearTarget)
                }
                .padding()
            }
            .navigationTitle("我的收入")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("晒一晒", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareCardSheet(
                    todayEarnings: store.todayEarnings,
                    monthEarnings: store.monthEarnings,
                    yearEarnings: store.yearEarnings,
                    isWorkday: store.isWorkdayToday,
                    brand: brand
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - 今日 Hero（渐变卡片，视觉主角）

    private var todayHero: some View {
        VStack(spacing: 14) {
            // 顶部状态行
            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                Text(statusText)
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.9))

            // 今日已赚大数字（休息日改显本月累计，不冷清）
            VStack(spacing: 6) {
                Text(store.isWorkdayToday ? "今日已赚" : "本月已赚")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(formatCurrency(store.isWorkdayToday ? store.todayEarnings : store.monthEarnings))
                    .font(.moneyHero(54))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    .numericRoll(value: store.isWorkdayToday ? store.todayEarnings : store.monthEarnings)
            }
            .padding(.vertical, 4)

            // 工作日：每秒跳动提示；休息日：温暖文案
            if store.isWorkdayToday {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold))
                    Text("每秒 +\(formatPerSecond(store.engine.salaryPerSecond(now: store.now)))")
                        .font(.callout.weight(.medium))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.white.opacity(0.18), in: Capsule())

                // 下班倒计时 + 实物换算（上瘾钩子）
                hookRow
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.caption2)
                    Text(restMessage)
                        .font(.callout.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.white.opacity(0.18), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(brand.heroGradient(isWorkday: store.isWorkdayToday))
        .clipShape(RoundedRectangle(cornerRadius: Brand.cornerLarge))
        .shadow(color: brand.primary.opacity(store.isWorkdayToday ? 0.28 : 0.0), radius: 16, y: 8)
        .shadow(color: Brand.accentWarm.opacity(store.isWorkdayToday ? 0.0 : 0.22), radius: 16, y: 8)
    }

    /// 上瘾钩子行：下班倒计时（盯着摸鱼）+ 实物换算（具象爽感）。
    @ViewBuilder
    private var hookRow: some View {
        VStack(spacing: 8) {
            if let countdown = store.clockOffCountdown {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.caption2.weight(.bold))
                    Text("距下班还有 \(countdown)")
                        .font(.footnote.weight(.medium))
                        .monospacedDigit()
                }
                .foregroundStyle(.white.opacity(0.95))
            }
            if let eq = store.earningsEquivalent {
                HStack(spacing: 6) {
                    Image(systemName: eq.icon)
                        .font(.caption2)
                    Text(eq.text)
                        .font(.footnote.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    /// 状态图标：补班/工作日用公文包，节假日用日历，普通休息日用咖啡杯。
    private var statusIcon: String {
        if store.todayHolidayName != nil {
            return store.isWorkdayToday ? "briefcase.fill" : "calendar"
        }
        return store.isWorkdayToday ? "briefcase.fill" : "cup.and.saucer.fill"
    }

    /// 状态文案：节假日显示节日名，让用户明白今天为何不计薪。
    private var statusText: String {
        if let name = store.todayHolidayName {
            return store.isWorkdayToday ? "\(name) · 今天上班" : "\(name) · 放假"
        }
        return store.isWorkdayToday ? "今天是工作日" : "今天是休息日"
    }

    /// 休息日温暖文案：节假日点出节日名，普通休息日给句轻松话。
    private var restMessage: String {
        if let name = store.todayHolidayName {
            return "\(name)快乐 · 好好休息"
        }
        return "今天不上班 · 好好歇着"
    }

    // MARK: - 节假日数据缺失横幅

    /// 当年法定节假日数据未内置时的提示。诚实告知用户：节假日/调休按星期几估算，可能不准。
    private var holidayDataBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(Brand.accentWarm)
            VStack(alignment: .leading, spacing: 2) {
                Text("今年节假日数据待更新")
                    .font(.subheadline.weight(.semibold))
                Text("节假日和调休暂按星期几估算，数字可能有偏差")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Brand.accentWarm.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Brand.cornerMedium))
    }
}

/// 统计卡片（带图标，留白精修）。
struct StatCard: View {
    let title: String
    let icon: String
    let amount: Double
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(brand.primary)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(formatCurrency(amount))
                .font(.moneyTitle)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary)
                .numericRoll(value: amount)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.cornerMedium))
    }
}

/// 预计今年总收入卡片：目标值 + 已赚进度。
struct YearTargetCard: View {
    let earned: Double
    let target: Double
    @Environment(\.brand) private var brand

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, earned / target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.footnote)
                    .foregroundStyle(brand.primary)
                Text("预计今年总收入")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(brand.primary)
            }

            Text(formatCurrency(target))
                .font(.moneyTitle)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary)

            // 已赚进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(brand.heroGradient)
                        .frame(width: progress * geo.size.width)
                }
            }
            .frame(height: 8)

            Text("已赚 \(formatCurrency(earned))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .numericRoll(value: earned)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.cornerMedium))
    }
}

#Preview {
    HomeView()
        .environmentObject(SalaryStore())
}

// MARK: - 数字平滑滚动（iOS 17+ 生效，iOS 16 降级为普通显示）

extension View {
    /// 金额变化时数字平滑滚动。iOS 16 无动画但正常显示。
    @ViewBuilder
    func numericRoll(value: Double) -> some View {
        if #available(iOS 17.0, *) {
            self
                .contentTransition(.numericText(value: value))
                .animation(.snappy(duration: 0.6), value: value)
        } else {
            self
        }
    }
}
