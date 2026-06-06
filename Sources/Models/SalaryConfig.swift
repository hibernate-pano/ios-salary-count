import Foundation

/// 工资配置（值类型，可持久化）。
///
/// 注意 weekday 约定与 Apple `Calendar` 一致：
/// 1 = 周日, 2 = 周一, 3 = 周二, 4 = 周三, 5 = 周四, 6 = 周五, 7 = 周六。
/// 默认工作日为周一到周五，即 `[2, 3, 4, 5, 6]`。
struct SalaryConfig: Codable, Equatable {
    /// 月薪（元）
    var monthlySalary: Double

    /// 上班时间（只取时:分有意义）
    var workStartTime: Date

    /// 下班时间（只取时:分有意义）
    var workEndTime: Date

    /// 是否启用午休
    var lunchEnabled: Bool

    /// 午休开始时间（只取时:分有意义）
    var lunchStartTime: Date

    /// 午休结束时间（只取时:分有意义）
    var lunchEndTime: Date

    /// 工作日集合，weekday 取值 1...7（见类型说明）
    var workDays: Set<Int>

    init(
        monthlySalary: Double = 3000,
        workStartTime: Date = SalaryConfig.time(hour: 9, minute: 0),
        workEndTime: Date = SalaryConfig.time(hour: 18, minute: 0),
        lunchEnabled: Bool = true,
        lunchStartTime: Date = SalaryConfig.time(hour: 12, minute: 0),
        lunchEndTime: Date = SalaryConfig.time(hour: 13, minute: 0),
        workDays: Set<Int> = [2, 3, 4, 5, 6]
    ) {
        self.monthlySalary = monthlySalary
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchEnabled = lunchEnabled
        self.lunchStartTime = lunchStartTime
        self.lunchEndTime = lunchEndTime
        self.workDays = workDays
    }

    /// 构造一个「今天的某个时刻」，仅用于承载时:分。
    static func time(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: calendar.startOfDay(for: Date())
        ) ?? Date()
    }
}
