import Foundation

/// 节假日 / 调休配置（值类型，可持久化）。
///
/// V1 不联网，默认无数据——此时工作日判断退化为「按星期几」。
/// 此模型与静态判断方法为后续接入法定节假日数据预留接口。
struct HolidayConfig: Codable, Equatable {
    /// 日期
    var date: Date

    /// 名称（如「春节」「国庆节」）
    var name: String

    /// 是否为调休补班日（true = 该休息日需上班）
    var isWorkday: Bool

    init(date: Date, name: String, isWorkday: Bool = false) {
        self.date = date
        self.name = name
        self.isWorkday = isWorkday
    }

    /// 该日期是否为（放假的）法定节假日。
    static func isHoliday(_ date: Date, holidays: [HolidayConfig], calendar: Calendar = .current) -> Bool {
        holidays.contains { calendar.isDate($0.date, inSameDayAs: date) && !$0.isWorkday }
    }

    /// 该日期是否为调休补班日。
    static func isMakeupWorkday(_ date: Date, holidays: [HolidayConfig], calendar: Calendar = .current) -> Bool {
        holidays.contains { calendar.isDate($0.date, inSameDayAs: date) && $0.isWorkday }
    }
}
