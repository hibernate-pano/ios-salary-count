import SwiftUI
import WidgetKit

// MARK: - 格式化

enum WidgetFormat {
    /// 金额：两位小数；≥1000 转整数 + 千分位（来自设计规格，保证小额也能看出在涨）。
    static func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        if value >= 1000 {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        let num = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "¥\(num)"
    }

    /// 百分比整数，如 "63%"。
    static func percent(_ progress: Double) -> String {
        "\(Int((progress * 100).rounded()))%"
    }

    /// 时长 "4h12m"。
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }

    /// 时刻 "09:42"。
    static func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 状态色与文案

extension SalaryEngine.DayState {
    /// 状态色相：工作中=品牌绿、休息=暖橙、午休/下班=灰。
    var dotColor: Color {
        switch self {
        case .working: return Brand.primary
        case .dayOff: return Color(red: 1.0, green: 0.58, blue: 0.30)
        case .lunch, .afterWork, .beforeWork: return .secondary
        }
    }

    var shortLabel: String {
        switch self {
        case .beforeWork: return "未开工"
        case .working: return "工作中"
        case .lunch: return "午休中"
        case .afterWork: return "已完成 ✓"
        case .dayOff: return "休息日 ☕️"
        }
    }
}

// MARK: - 液体填充（财富蓄满）

/// 圆形容器，液体从底部按进度填满，配品牌渐变 + 波浪顶边。
/// 「钱在蓄满」的积累感比进度环更贴合工资主题。
struct LiquidFill: View {
    let progress: Double          // 0...1
    var isRest: Bool = false      // 休息日用暖橙渐变

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                // 容器底（淡）
                Circle()
                    .fill(Color(.quaternaryLabel).opacity(0.4))

                // 液体（裁剪在圆内，从底部按进度升高）
                WaveShape(progress: clamped, waveHeight: d * 0.025)
                    .fill(isRest ? Brand.restGradient : Brand.heroGradient)
                    .clipShape(Circle())

                // 圆环描边
                Circle()
                    .stroke(Color(.quaternaryLabel), lineWidth: 1.5)
            }
            .frame(width: d, height: d)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var clamped: Double { min(1, max(0, progress)) }
}

/// 按进度从底部填充的波浪形状（顶边一条浅波浪，增加「液体」生动感）。
private struct WaveShape: Shape {
    var progress: Double
    var waveHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 液面 y：progress=0 在底部(maxY)，=1 在顶部(minY)
        let level = rect.maxY - CGFloat(progress) * rect.height
        let w = rect.width

        p.move(to: CGPoint(x: rect.minX, y: level))
        // 顶边正弦波（两个波峰）
        let steps = 24
        for i in 0...steps {
            let x = rect.minX + w * CGFloat(i) / CGFloat(steps)
            let phase = CGFloat(i) / CGFloat(steps) * .pi * 2 * 2
            let y = level + sin(phase) * waveHeight
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 进度环（保留备用）

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    var dashed: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.quaternaryLabel), style: StrokeStyle(lineWidth: lineWidth))
            if dashed {
                Circle()
                    .stroke(Color(.tertiaryLabel),
                            style: StrokeStyle(lineWidth: lineWidth, dash: [3, 4]))
            } else {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

// MARK: - 容器背景（iOS17+ containerBackground 兼容）

extension View {
    /// iOS17+ 用 containerBackground，老系统补一个观感一致的背景。
    @ViewBuilder
    func widgetContainerBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.padding()
                .background(Color(.tertiarySystemFill))
        }
    }
}
