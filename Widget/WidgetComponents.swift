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
