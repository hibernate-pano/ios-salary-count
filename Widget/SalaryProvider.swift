import WidgetKit
import Foundation

/// Widget 时间线条目：携带某一时刻的工资快照。
///
/// 因为 SalaryEngine 是纯函数，每个 entry 都是该时刻的真实计算值，
/// 而非动画造假——系统按 entry 的 date 切换显示，制造"在推进"的观感。
struct SalaryEntry: TimelineEntry {
    let date: Date
    let todayEarnings: Double
    let monthEarnings: Double
    let yearEarnings: Double
    let expectedTodayTotal: Double   // 预计今日满勤（dailySalary）
    let progress: Double             // 今日工作进度 0...1
    let workedSeconds: TimeInterval
    let totalWorkSeconds: TimeInterval
    let state: SalaryEngine.DayState
    let workStart: Date
    let workEnd: Date
    let isConfigured: Bool           // App Group 未配置时为 false，渲染引导提示
    let theme: AccentTheme           // 跟随 App 的配色主题

    /// 从配置和指定时刻构造一个 entry。
    static func make(config: SalaryConfig, at date: Date, isConfigured: Bool = true) -> SalaryEntry {
        let engine = SalaryEngine(config: config, holidays: HolidayData.currentYear(now: date))
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        func anchor(_ minutes: Int) -> Date {
            cal.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
        }
        return SalaryEntry(
            date: date,
            todayEarnings: engine.todayEarnings(now: date),
            monthEarnings: engine.monthEarnings(now: date),
            yearEarnings: engine.yearEarnings(now: date),
            expectedTodayTotal: engine.dailySalary(now: date),
            progress: engine.progress(now: date),
            workedSeconds: engine.secondsWorkedToday(now: date),
            totalWorkSeconds: engine.dailyWorkSeconds,
            state: engine.dayState(now: date),
            workStart: anchor(config.workStartMinutes),
            workEnd: anchor(config.workEndMinutes),
            isConfigured: isConfigured,
            theme: AccentTheme.loadShared()
        )
    }

    /// 未配置占位条目（App Group 读不到配置时）。
    static func unconfigured(at date: Date) -> SalaryEntry {
        make(config: SalaryConfig(), at: date, isConfigured: false)
    }
}

struct SalaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SalaryEntry {
        SalaryEntry.make(config: SalaryConfig(), at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryEntry) -> Void) {
        guard let config = SalaryConfig.loadSharedIfPresent() else {
            completion(SalaryEntry.unconfigured(at: Date()))
            return
        }
        completion(SalaryEntry.make(config: config, at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryEntry>) -> Void) {
        // 未配置：显示引导，1 小时后再问（用户可能刚装还没打开 App）。
        guard let config = SalaryConfig.loadSharedIfPresent() else {
            let entry = SalaryEntry.unconfigured(at: Date())
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
            return
        }

        let now = Date()
        let engine = SalaryEngine(config: config, holidays: HolidayData.currentYear(now: now))
        let cal = Calendar.current
        let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)

        switch engine.dayState(now: now) {
        case .dayOff, .afterWork, .beforeWork:
            // 非工作时段：单条快照。重建点取「下一个开工时刻」与「次日 0 点」的较早者，
            // 保证跨日后状态/月年累计及时刷新（修复跨日陈旧 + beforeWork 永不出现）。
            let entry = SalaryEntry.make(config: config, at: now)
            let nextWork = nextRefreshDate(after: now, config: config, engine: engine)
            let next = min(nextWork, nextMidnight)
            completion(Timeline(entries: [entry], policy: .after(next)))

        case .working, .lunch:
            // 工作时段：每 10 分钟一个真实快照 + 状态切换断点强插。
            let startOfDay = cal.startOfDay(for: now)
            func anchor(_ minutes: Int) -> Date {
                cal.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
            }
            let workEnd = anchor(config.workEndMinutes)

            var dates: Set<Date> = [now]
            var t = now
            while t < workEnd {
                dates.insert(t)
                t = t.addingTimeInterval(600)
            }
            // 强插状态切换断点
            for m in [config.lunchStartMinutes, config.lunchEndMinutes] {
                let bp = anchor(m)
                if bp > now && bp <= workEnd { dates.insert(bp) }
            }
            dates.insert(workEnd)

            let entries = dates.sorted().map { SalaryEntry.make(config: config, at: $0) }
            completion(Timeline(entries: entries, policy: .after(workEnd)))
        }
    }

    /// 下一次该重建时间线的时刻：下一个工作日的上班时间。
    /// 找不到（如 workDays 为空）时返回远期时间，避免高频无效唤醒耗尽刷新预算。
    private func nextRefreshDate(after now: Date, config: SalaryConfig, engine: SalaryEngine) -> Date {
        let cal = Calendar.current
        for offset in 0...8 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let startOfDay = cal.startOfDay(for: day)
            let workStart = cal.date(byAdding: .minute, value: config.workStartMinutes, to: startOfDay) ?? startOfDay
            if workStart > now && engine.isWorkday(workStart) {
                return workStart
            }
        }
        // 8 天内无工作日（如空 workDays）：3 天后再问，不要每小时空转。
        return cal.date(byAdding: .day, value: 3, to: now) ?? now.addingTimeInterval(86400)
    }
}
