import Foundation

/// 工资配置（值类型，可持久化）。
///
/// 时间一律以「自当日午夜起的分钟数」存储（Int），彻底脱离绝对时刻与时区——
/// App 与 Widget 两个进程在任意时区/夏令时下解读完全一致。
/// 对外用 Date 桥接属性，方便 SwiftUI 的 DatePicker 绑定。
///
/// weekday 约定与 Apple `Calendar` 一致：
/// 1=周日, 2=周一, 3=周三…7=周六。默认工作日周一到周五 `[2,3,4,5,6]`。
struct SalaryConfig: Codable, Equatable {
    /// 月薪（元）
    var monthlySalary: Double

    /// 上班时间，自午夜起的分钟数（如 9:00 = 540）
    var workStartMinutes: Int

    /// 下班时间，自午夜起的分钟数（如 18:00 = 1080）
    var workEndMinutes: Int

    /// 是否启用午休
    var lunchEnabled: Bool

    /// 午休开始，自午夜起的分钟数
    var lunchStartMinutes: Int

    /// 午休结束，自午夜起的分钟数
    var lunchEndMinutes: Int

    /// 工作日集合，weekday 取值 1...7（见类型说明）
    var workDays: Set<Int>

    // MARK: - 主初始化器（分钟）

    init(
        monthlySalary: Double = 3000,
        workStartMinutes: Int = 9 * 60,
        workEndMinutes: Int = 18 * 60,
        lunchEnabled: Bool = true,
        lunchStartMinutes: Int = 12 * 60,
        lunchEndMinutes: Int = 13 * 60,
        workDays: Set<Int> = [2, 3, 4, 5, 6]
    ) {
        self.monthlySalary = monthlySalary
        self.workStartMinutes = workStartMinutes
        self.workEndMinutes = workEndMinutes
        self.lunchEnabled = lunchEnabled
        self.lunchStartMinutes = lunchStartMinutes
        self.lunchEndMinutes = lunchEndMinutes
        self.workDays = workDays
    }

    // MARK: - 便利初始化器（Date，兼容 UI 与测试）

    init(
        monthlySalary: Double = 3000,
        workStartTime: Date,
        workEndTime: Date,
        lunchEnabled: Bool = true,
        lunchStartTime: Date,
        lunchEndTime: Date,
        workDays: Set<Int> = [2, 3, 4, 5, 6]
    ) {
        self.init(
            monthlySalary: monthlySalary,
            workStartMinutes: SalaryConfig.minutes(of: workStartTime),
            workEndMinutes: SalaryConfig.minutes(of: workEndTime),
            lunchEnabled: lunchEnabled,
            lunchStartMinutes: SalaryConfig.minutes(of: lunchStartTime),
            lunchEndMinutes: SalaryConfig.minutes(of: lunchEndTime),
            workDays: workDays
        )
    }

    // MARK: - Date 桥接（给 DatePicker 用，投影到今日）

    var workStartTime: Date {
        get { SalaryConfig.date(fromMinutes: workStartMinutes) }
        set { workStartMinutes = SalaryConfig.minutes(of: newValue) }
    }
    var workEndTime: Date {
        get { SalaryConfig.date(fromMinutes: workEndMinutes) }
        set { workEndMinutes = SalaryConfig.minutes(of: newValue) }
    }
    var lunchStartTime: Date {
        get { SalaryConfig.date(fromMinutes: lunchStartMinutes) }
        set { lunchStartMinutes = SalaryConfig.minutes(of: newValue) }
    }
    var lunchEndTime: Date {
        get { SalaryConfig.date(fromMinutes: lunchEndMinutes) }
        set { lunchEndMinutes = SalaryConfig.minutes(of: newValue) }
    }

    // MARK: - Codable：只编码分钟字段，Date 桥接不参与

    private enum CodingKeys: String, CodingKey {
        case monthlySalary, workStartMinutes, workEndMinutes
        case lunchEnabled, lunchStartMinutes, lunchEndMinutes, workDays
    }

    // MARK: - 时间换算工具

    /// 从 Date 提取「自午夜起的分钟数」。
    static func minutes(of date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// 把「自午夜起的分钟数」投影到今天的对应时刻（仅供 UI 显示）。
    static func date(fromMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: calendar.startOfDay(for: Date())
        ) ?? Date()
    }

    /// 构造承载时:分的 Date（兼容旧测试 API）。
    static func time(hour: Int, minute: Int) -> Date {
        date(fromMinutes: hour * 60 + minute)
    }
}
