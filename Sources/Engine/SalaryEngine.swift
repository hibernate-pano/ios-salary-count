import Foundation

/// 工资计算引擎。
///
/// 全部为纯函数：给定 `SalaryConfig` 和一个参考时刻，结果完全确定，
/// 不依赖任何隐藏状态，方便测试。
struct SalaryEngine {
    let config: SalaryConfig
    let holidays: [HolidayConfig]
    var calendar: Calendar

    init(config: SalaryConfig, holidays: [HolidayConfig] = [], calendar: Calendar = .current) {
        self.config = config
        self.holidays = holidays
        self.calendar = calendar
    }

    // MARK: - 基础时长

    /// 下班相对上班的分钟跨度。
    /// V1 不支持跨午夜班次（下班≤上班视为无效配置 → 跨度为 0，收入归零）。
    /// 原因：跨午夜班次的"今日收入"跨两个日历日，与按日历日统计的模型不兼容。夜班支持见路线图。
    private var workSpanMinutes: Int {
        max(0, config.workEndMinutes - config.workStartMinutes)
    }

    /// 午休时长（分钟）。仅当启用且时长为正时有效。
    private var lunchSpanMinutes: Int {
        guard config.lunchEnabled else { return 0 }
        let span = config.lunchEndMinutes - config.lunchStartMinutes
        return span > 0 ? span : 0
    }

    /// 每日有效工作秒数 = (下班 − 上班) − 午休时长。无效配置时为 0。
    var dailyWorkSeconds: TimeInterval {
        let net = workSpanMinutes - lunchSpanMinutes
        return TimeInterval(max(0, net) * 60)
    }

    // MARK: - 工作日计数

    /// 指定年月内的工作日天数（weekday ∈ config.workDays）。
    func workDays(year: Int, month: Int) -> Int {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return 0
        }

        var count = 0
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                let weekday = calendar.component(.weekday, from: date)
                if config.workDays.contains(weekday) {
                    count += 1
                }
            }
        }
        return count
    }

    /// 判断某天是否为工作日。
    /// 优先级：调休补班 > 法定节假日 > 按星期几（V1 默认 holidays 为空，退化为按星期几）。
    func isWorkday(_ date: Date) -> Bool {
        if HolidayConfig.isMakeupWorkday(date, holidays: holidays, calendar: calendar) { return true }
        if HolidayConfig.isHoliday(date, holidays: holidays, calendar: calendar) { return false }
        let weekday = calendar.component(.weekday, from: date)
        return config.workDays.contains(weekday)
    }

    /// 当天匹配的节假日名（如「春节」「国庆调休」）；非节假日返回 nil。
    func holidayName(for date: Date) -> String? {
        holidays.first { calendar.isDate($0.date, inSameDayAs: date) }?.name
    }

    // MARK: - 工资单价

    /// 指定月份的日工资 = 月薪 / 当月工作日数。
    func dailySalary(now: Date) -> Double {
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let days = workDays(year: year, month: month)
        guard days > 0 else { return 0 }
        return config.monthlySalary / Double(days)
    }

    /// 每秒工资 = 日工资 / 每日工作秒数。
    func salaryPerSecond(now: Date) -> Double {
        let seconds = dailyWorkSeconds
        guard seconds > 0 else { return 0 }
        return dailySalary(now: now) / seconds
    }

    // MARK: - 今日已工作秒数

    /// 把「自午夜分钟数」投影到 `day` 当天的绝对时刻。
    private func anchor(_ minutes: Int, on day: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
    }

    /// 今日上班的绝对起止时刻。下班≤上班为无效配置，返回零跨度窗口（收入归零）。
    private func workWindow(on day: Date) -> (start: Date, end: Date) {
        let start = anchor(config.workStartMinutes, on: day)
        let end = anchor(config.workEndMinutes, on: day)
        return end > start ? (start, end) : (start, start)
    }

    /// 今日午休的绝对起止时刻；无效午休返回 nil。
    private func lunchWindow(on day: Date) -> (start: Date, end: Date)? {
        guard lunchSpanMinutes > 0 else { return nil }
        let start = anchor(config.lunchStartMinutes, on: day)
        let end = anchor(config.lunchEndMinutes, on: day)
        return end > start ? (start, end) : nil
    }

    /// 截至 `now`，今天已工作的秒数。
    /// 非工作日 → 0；上班前 → 0；午休中 → 仅上班到午休的部分；
    /// 下班后 → 封顶 dailyWorkSeconds；工作中 → 已过秒数（过了午休则扣掉）。
    func secondsWorkedToday(now: Date) -> TimeInterval {
        guard isWorkday(now) else { return 0 }

        let (workStart, workEnd) = workWindow(on: now)

        if now <= workStart { return 0 }
        if now >= workEnd { return dailyWorkSeconds }

        var worked = now.timeIntervalSince(workStart)

        if let (lunchStart, lunchEnd) = lunchWindow(on: now) {
            let lunchDuration = lunchEnd.timeIntervalSince(lunchStart)
            if now >= lunchStart && now <= lunchEnd {
                // 午休中：只算上班到午休开始
                worked = lunchStart.timeIntervalSince(workStart)
            } else if now > lunchEnd {
                // 午休后：扣掉整段午休
                worked -= lunchDuration
            }
        }

        return max(0, min(worked, dailyWorkSeconds))
    }

    // MARK: - 收入

    /// 今日收入。
    func todayEarnings(now: Date) -> Double {
        secondsWorkedToday(now: now) * salaryPerSecond(now: now)
    }

    /// 本月累计收入 = 本月今天之前已完成的工作日 × 日工资 + 今日收入。
    func monthEarnings(now: Date) -> Double {
        let today = calendar.component(.day, from: now)
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        var completedWorkdays = 0
        if today > 1 {
            for day in 1..<today {
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                   isWorkday(date) {
                    completedWorkdays += 1
                }
            }
        }

        return Double(completedWorkdays) * dailySalary(now: now) + todayEarnings(now: now)
    }

    /// 年度累计收入 = 已过完整月份的月薪之和 + 本月累计收入。
    func yearEarnings(now: Date) -> Double {
        let month = calendar.component(.month, from: now)
        let completedMonths = month - 1
        return Double(completedMonths) * config.monthlySalary + monthEarnings(now: now)
    }

    // MARK: - 工作进度与状态（Widget 用）

    /// 今日工作进度比例 0...1（已工作秒数 / 每日工作秒数）。
    func progress(now: Date) -> Double {
        let total = dailyWorkSeconds
        guard total > 0 else { return 0 }
        return min(1.0, max(0, secondsWorkedToday(now: now) / total))
    }

    /// 当日工作状态。
    enum DayState {
        case beforeWork   // 工作日，但还没到上班时间
        case working      // 工作日，工作中
        case lunch        // 工作日，午休中
        case afterWork    // 工作日，已下班
        case dayOff       // 非工作日
    }

    /// 判断 `now` 时刻的当日状态。
    func dayState(now: Date) -> DayState {
        guard isWorkday(now) else { return .dayOff }

        let (workStart, workEnd) = workWindow(on: now)

        if now < workStart { return .beforeWork }
        if now >= workEnd { return .afterWork }

        if let (lunchStart, lunchEnd) = lunchWindow(on: now),
           now >= lunchStart, now < lunchEnd {
            return .lunch
        }
        return .working
    }

    /// 距下班还剩的有效工作秒数（已扣午休）。下班后为 0。
    func remainingWorkSeconds(now: Date) -> TimeInterval {
        max(0, dailyWorkSeconds - secondsWorkedToday(now: now))
    }
}
