import Foundation

/// 中国法定节假日数据（内置，不联网）。
///
/// 数据来源：国务院办公厅关于部分节假日安排的通知。
/// `isWorkday=false` 为放假日，`isWorkday=true` 为调休补班日（该周末需上班）。
///
/// 维护：每年国务院 12 月左右发布次年安排，届时在此补充新年份数据。
enum HolidayData {

    /// 取指定年份的节假日数据；无数据返回空数组（退化为按星期几判断）。
    static func holidays(year: Int) -> [HolidayConfig] {
        switch year {
        case 2026: return year2026
        default: return []
        }
    }

    /// 当前年份的节假日数据。
    static func currentYear(calendar: Calendar = .current, now: Date = Date()) -> [HolidayConfig] {
        holidays(year: calendar.component(.year, from: now))
    }

    // MARK: - 2026

    /// 2026 年法定节假日与调休安排。
    private static let year2026: [HolidayConfig] = build([
        // 元旦：1/1–1/3 放假，1/4 补班
        .off(2026, 1, 1, "元旦"), .off(2026, 1, 2, "元旦"), .off(2026, 1, 3, "元旦"),
        .work(2026, 1, 4, "元旦调休"),
        // 春节：2/15–2/23 放假，2/14、2/28 补班
        .work(2026, 2, 14, "春节调休"),
        .off(2026, 2, 15, "春节"), .off(2026, 2, 16, "春节"), .off(2026, 2, 17, "春节"),
        .off(2026, 2, 18, "春节"), .off(2026, 2, 19, "春节"), .off(2026, 2, 20, "春节"),
        .off(2026, 2, 21, "春节"), .off(2026, 2, 22, "春节"), .off(2026, 2, 23, "春节"),
        .work(2026, 2, 28, "春节调休"),
        // 清明：4/4–4/6 放假，无补班
        .off(2026, 4, 4, "清明节"), .off(2026, 4, 5, "清明节"), .off(2026, 4, 6, "清明节"),
        // 劳动节：5/1–5/5 放假，5/9 补班
        .off(2026, 5, 1, "劳动节"), .off(2026, 5, 2, "劳动节"), .off(2026, 5, 3, "劳动节"),
        .off(2026, 5, 4, "劳动节"), .off(2026, 5, 5, "劳动节"),
        .work(2026, 5, 9, "劳动节调休"),
        // 端午：6/19–6/21 放假，无补班
        .off(2026, 6, 19, "端午节"), .off(2026, 6, 20, "端午节"), .off(2026, 6, 21, "端午节"),
        // 中秋：9/25–9/27 放假，无补班
        .off(2026, 9, 25, "中秋节"), .off(2026, 9, 26, "中秋节"), .off(2026, 9, 27, "中秋节"),
        // 国庆：10/1–10/7 放假，9/20、10/10 补班
        .work(2026, 9, 20, "国庆调休"),
        .off(2026, 10, 1, "国庆节"), .off(2026, 10, 2, "国庆节"), .off(2026, 10, 3, "国庆节"),
        .off(2026, 10, 4, "国庆节"), .off(2026, 10, 5, "国庆节"), .off(2026, 10, 6, "国庆节"),
        .off(2026, 10, 7, "国庆节"),
        .work(2026, 10, 10, "国庆调休"),
    ])

    // MARK: - 构造辅助

    /// 紧凑的数据条目，延迟到 build 时转成带 Date 的 HolidayConfig。
    private struct Spec {
        let y: Int, m: Int, d: Int, name: String, isWorkday: Bool
        static func off(_ y: Int, _ m: Int, _ d: Int, _ name: String) -> Spec {
            Spec(y: y, m: m, d: d, name: name, isWorkday: false)
        }
        static func work(_ y: Int, _ m: Int, _ d: Int, _ name: String) -> Spec {
            Spec(y: y, m: m, d: d, name: name, isWorkday: true)
        }
    }

    private static func build(_ specs: [Spec]) -> [HolidayConfig] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return specs.compactMap { s in
            guard let date = calendar.date(from: DateComponents(year: s.y, month: s.m, day: s.d)) else { return nil }
            return HolidayConfig(date: date, name: s.name, isWorkday: s.isWorkday)
        }
    }
}
