import SwiftUI
import WidgetKit

// MARK: - Small：今日进度环

struct SmallSalaryView: View {
    let entry: SalaryEntry

    /// 环心主金额：休息日显示本月累计，上班前显示预计今日，其余显示今日已赚。
    private var centerAmount: Double {
        switch entry.state {
        case .dayOff: return entry.monthEarnings
        case .beforeWork: return entry.expectedTodayTotal
        default: return entry.todayEarnings
        }
    }

    private var centerSubtitle: String {
        switch entry.state {
        case .beforeWork: return "未开工"
        case .working, .lunch: return WidgetFormat.percent(entry.progress)
        case .afterWork: return "已完成 ✓"
        case .dayOff: return "休息日 ☕️"
        }
    }

    private var topLabel: String {
        switch entry.state {
        case .dayOff: return "本月"
        case .beforeWork: return "预计今日"
        default: return "今日"
        }
    }

    private var bottomText: String {
        switch entry.state {
        case .beforeWork: return "上班 \(WidgetFormat.clock(entry.workStart))"
        case .afterWork: return "明天见"
        case .dayOff: return "好好休息"
        default: return "截至 \(WidgetFormat.clock(entry.date))"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(topLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(entry.state.dotColor)
                    .frame(width: 8, height: 8)
            }

            ZStack {
                ProgressRing(
                    progress: entry.progress,
                    lineWidth: 10,
                    dashed: entry.state == .dayOff
                )
                VStack(spacing: 2) {
                    Text(WidgetFormat.currency(centerAmount))
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(centerSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
            }

            Text(bottomText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .widgetContainerBackground()
    }
}

// MARK: - Medium：左环右文

struct MediumSalaryView: View {
    let entry: SalaryEntry

    private var todayLine: (label: String, amount: Double) {
        entry.state == .beforeWork ? ("预计今日", entry.expectedTodayTotal) : ("今日", entry.todayEarnings)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 左：进度环
            ZStack {
                ProgressRing(
                    progress: entry.progress,
                    lineWidth: 11,
                    dashed: entry.state == .dayOff
                )
                VStack(spacing: 2) {
                    Text(WidgetFormat.currency(entry.state == .dayOff ? entry.monthEarnings : entry.todayEarnings))
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(entry.state == .dayOff ? "本月" : WidgetFormat.percent(entry.progress))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 110)

            // 右：文字信息
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Circle().fill(entry.state.dotColor).frame(width: 7, height: 7)
                    Text(entry.state.shortLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(todayLine.label) \(WidgetFormat.currency(todayLine.amount))")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    if entry.state != .dayOff {
                        Text("/ 预计 \(WidgetFormat.currency(entry.expectedTodayTotal))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                ProgressBar(progress: entry.progress)
                    .frame(height: 6)

                Text("已工作 \(WidgetFormat.duration(entry.workedSeconds)) / 共 \(WidgetFormat.duration(entry.totalWorkSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack {
                    Text("本月累计 \(WidgetFormat.currency(entry.monthEarnings))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .lineLimit(1)
                    Spacer()
                    Text("截至 \(WidgetFormat.clock(entry.date))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .widgetContainerBackground()
    }
}

// MARK: - Large：今日 hero + 进度 + 本月/年度

struct LargeSalaryView: View {
    let entry: SalaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 区一：今日 hero
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Circle().fill(entry.state.dotColor).frame(width: 8, height: 8)
                    Text(entry.state == .dayOff ? "本月已赚" : "今日已赚")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.state.shortLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(WidgetFormat.currency(entry.state == .dayOff ? entry.monthEarnings : entry.todayEarnings))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.tint)
            }

            // 区二：进度条 + 两端锚点
            if entry.state != .dayOff {
                VStack(spacing: 6) {
                    Text("预计今日满勤 \(WidgetFormat.currency(entry.expectedTodayTotal))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                    ProgressBar(progress: entry.progress)
                        .frame(height: 8)
                    HStack {
                        Text("\(WidgetFormat.clock(entry.workStart)) 上班")
                        Spacer()
                        Text(WidgetFormat.percent(entry.progress))
                        Spacer()
                        Text("\(WidgetFormat.clock(entry.workEnd)) 下班")
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Divider()

            // 区三：本月 / 年度
            HStack(spacing: 16) {
                StatColumn(title: "本月累计", amount: entry.monthEarnings)
                StatColumn(title: "年度累计", amount: entry.yearEarnings)
            }

            Spacer(minLength: 0)

            // 区四：状态条
            Text("截至 \(WidgetFormat.clock(entry.date)) 更新")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .widgetContainerBackground()
    }
}

// MARK: - 复用小件

struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.quaternaryLabel))
                Capsule().fill(.tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
    }
}

struct StatColumn: View {
    let title: String
    let amount: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(WidgetFormat.currency(amount))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// App Group 读不到配置时的引导视图（用户刚装、还没打开过 App）。
struct UnconfiguredView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "yensign.circle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("打开 App 设置工资")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .widgetContainerBackground()
    }
}
