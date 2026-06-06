import Foundation

/// 工资计算引擎。
///
/// 全部为纯函数：给定 `SalaryConfig` 和一个参考时刻，结果完全确定，
/// 不依赖任何隐藏状态，方便测试。
struct SalaryEngine {
    let config: SalaryConfig
    var calendar: Calendar

    init(config: SalaryConfig, calendar: Calendar = .current) {
        self.config = config
        self.calendar = calendar
    }

    // MARK: - 基础时长

    /// 某个 Date 的「当天零点起的秒数」，只取时:分。
    private func secondsOfDay(_ date: Date) -> TimeInterval {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return TimeInterval(hour * 3600 + minute * 60)
    }

    /// 每日有效工作秒数 = (下班 − 上班) − 午休时长。
    var dailyWorkSeconds: TimeInterval {
        let work = secondsOfDay(config.workEndTime) - secondsOfDay(config.workStartTime)
        guard work > 0 else { return 0 }

        if config.lunchEnabled {
            let lunch = secondsOfDay(config.lunchEndTime) - secondsOfDay(config.lunchStartTime)
            if lunch > 0 {
                return max(0, work - lunch)
            }
        }
        return work
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

    /// 判断某天是否为工作日（仅看 weekday，V1 不含节假日）。
    func isWorkday(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return config.workDays.contains(weekday)
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

    /// 把 config 里的「时:分」投影到指定日期的同一天。
    private func timeToday(_ time: Date, on day: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }

    /// 截至 `now`，今天已工作的秒数。
    /// 非工作日 → 0；上班前 → 0；午休中 → 仅上班到午休的部分；
    /// 下班后 → 封顶 dailyWorkSeconds；工作中 → 已过秒数（过了午休则扣掉）。
    func secondsWorkedToday(now: Date) -> TimeInterval {
        guard isWorkday(now) else { return 0 }

        let workStart = timeToday(config.workStartTime, on: now)
        let workEnd = timeToday(config.workEndTime, on: now)

        if now <= workStart { return 0 }
        if now >= workEnd { return dailyWorkSeconds }

        var worked = now.timeIntervalSince(workStart)

        if config.lunchEnabled {
            let lunchStart = timeToday(config.lunchStartTime, on: now)
            let lunchEnd = timeToday(config.lunchEndTime, on: now)
            let lunchDuration = lunchEnd.timeIntervalSince(lunchStart)

            if lunchDuration > 0 {
                if now >= lunchStart && now <= lunchEnd {
                    // 午休中：只算上班到午休开始
                    worked = lunchStart.timeIntervalSince(workStart)
                } else if now > lunchEnd {
                    // 午休后：扣掉整段午休
                    worked -= lunchDuration
                }
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
}
