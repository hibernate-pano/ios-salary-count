import XCTest
@testable import SalaryCount

final class SalaryEngineTests: XCTestCase {

    /// 固定日历，避免时区/区域差异影响断言。
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return cal
    }

    /// 构造一个指定年月日时分的 Date。
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// 标准配置：月薪 3000，9:00-18:00，午休 12:00-13:00，周一到周五。
    private func makeConfig(
        monthlySalary: Double = 3000,
        lunchEnabled: Bool = true,
        workDays: Set<Int> = [2, 3, 4, 5, 6]
    ) -> SalaryConfig {
        SalaryConfig(
            monthlySalary: monthlySalary,
            workStartTime: SalaryConfig.time(hour: 9, minute: 0),
            workEndTime: SalaryConfig.time(hour: 18, minute: 0),
            lunchEnabled: lunchEnabled,
            lunchStartTime: SalaryConfig.time(hour: 12, minute: 0),
            lunchEndTime: SalaryConfig.time(hour: 13, minute: 0),
            workDays: workDays
        )
    }

    // MARK: - 每日工作秒数

    func testDailyWorkSeconds_withLunch_is8Hours() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        XCTAssertEqual(engine.dailyWorkSeconds, 8 * 3600, "9-18点含1小时午休应为8小时")
    }

    func testDailyWorkSeconds_withoutLunch_is9Hours() {
        let engine = SalaryEngine(config: makeConfig(lunchEnabled: false), calendar: calendar)
        XCTAssertEqual(engine.dailyWorkSeconds, 9 * 3600, "无午休应为9小时")
    }

    // MARK: - 工作日约定（修复 weekday bug）

    func testWorkday_mondayToFriday() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        // 2024-03-11 是周一，2024-03-15 是周五
        XCTAssertTrue(engine.isWorkday(date(2024, 3, 11)), "周一应是工作日")
        XCTAssertTrue(engine.isWorkday(date(2024, 3, 15)), "周五应是工作日")
        // 2024-03-16 周六，2024-03-17 周日
        XCTAssertFalse(engine.isWorkday(date(2024, 3, 16)), "周六不应是工作日")
        XCTAssertFalse(engine.isWorkday(date(2024, 3, 17)), "周日不应是工作日")
    }

    func testWorkDaysInMonth_march2024_is21() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        // 2024年3月有21个工作日（周一到周五）
        XCTAssertEqual(engine.workDays(year: 2024, month: 3), 21)
    }

    // MARK: - 每秒工资

    func testSalaryPerSecond() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 10, 0) // 3月，21个工作日
        let expectedDaily = 3000.0 / 21.0
        let expectedPerSecond = expectedDaily / (8 * 3600)
        XCTAssertEqual(engine.salaryPerSecond(now: now), expectedPerSecond, accuracy: 1e-9)
    }

    // MARK: - 今日已工作秒数

    func testSecondsWorked_beforeWork_isZero() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 8, 0) // 上班前
        XCTAssertEqual(engine.secondsWorkedToday(now: now), 0)
    }

    func testSecondsWorked_duringMorning() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 10, 30) // 上班1.5小时
        XCTAssertEqual(engine.secondsWorkedToday(now: now), 1.5 * 3600, accuracy: 1)
    }

    func testSecondsWorked_duringLunch_cappedAtMorning() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 12, 30) // 午休中
        XCTAssertEqual(engine.secondsWorkedToday(now: now), 3 * 3600, accuracy: 1, "午休中应封顶到上午3小时")
    }

    func testSecondsWorked_afternoon_deductsLunch() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 14, 0) // 下午2点：上班5小时-1小时午休=4小时
        XCTAssertEqual(engine.secondsWorkedToday(now: now), 4 * 3600, accuracy: 1)
    }

    func testSecondsWorked_afterWork_isFullDay() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 20, 0) // 下班后
        XCTAssertEqual(engine.secondsWorkedToday(now: now), 8 * 3600, accuracy: 1)
    }

    // MARK: - 收入

    func testTodayEarnings_onWeekend_isZero() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 16, 14, 0) // 周六下午
        XCTAssertEqual(engine.todayEarnings(now: now), 0, "周末收入应为0")
    }

    func testTodayEarnings_fullWorkday_equalsDailySalary() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 20, 0) // 工作日下班后 = 一整天日工资
        let expectedDaily = 3000.0 / 21.0
        XCTAssertEqual(engine.todayEarnings(now: now), expectedDaily, accuracy: 1e-6)
    }

    func testMonthEarnings_accumulatesCompletedWorkdays() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        // 2024-03-13 周三下班后。3月1日到12日的工作日数：
        // 1(五),4,5,6,7,8(周一到五),11,12 → 共8个完成的工作日 + 今天
        let now = date(2024, 3, 13, 20, 0)
        let dailySalary = 3000.0 / 21.0
        XCTAssertEqual(engine.monthEarnings(now: now), dailySalary * 9, accuracy: 1e-6)
    }

    func testYearEarnings_includesCompletedMonths() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 20, 0) // 3月 → 前2个月完整月薪
        let expected = 3000.0 * 2 + engine.monthEarnings(now: now)
        XCTAssertEqual(engine.yearEarnings(now: now), expected, accuracy: 1e-6)
    }

    // MARK: - 边界

    func testZeroSalary_producesZeroEarnings() {
        let engine = SalaryEngine(config: makeConfig(monthlySalary: 0), calendar: calendar)
        let now = date(2024, 3, 13, 14, 0)
        XCTAssertEqual(engine.todayEarnings(now: now), 0)
        XCTAssertEqual(engine.salaryPerSecond(now: now), 0)
    }

    func testNoWorkDays_doesNotCrash() {
        let engine = SalaryEngine(config: makeConfig(workDays: []), calendar: calendar)
        let now = date(2024, 3, 13, 14, 0)
        XCTAssertEqual(engine.dailySalary(now: now), 0, "无工作日时日工资应为0而非崩溃")
        XCTAssertEqual(engine.todayEarnings(now: now), 0)
    }

    // MARK: - 跨午夜班次（V1 不支持，应安全归零而非算错）

    /// 22:00 上班、次日 06:00 下班——V1 视为无效配置（下班≤上班）。
    private func makeNightShift() -> SalaryConfig {
        SalaryConfig(
            monthlySalary: 6000,
            workStartMinutes: 22 * 60,
            workEndMinutes: 6 * 60,
            lunchEnabled: false,
            workDays: [1, 2, 3, 4, 5, 6, 7]
        )
    }

    func testOvernightShift_treatedAsZeroNotMiscalculated() {
        let engine = SalaryEngine(config: makeNightShift(), calendar: calendar)
        // V1 明确不支持跨午夜：安全归零，不误导金额（夜班支持见路线图）
        XCTAssertEqual(engine.dailyWorkSeconds, 0, "跨午夜班次 V1 不支持，应归零而非算出错误工时")
        XCTAssertEqual(engine.salaryPerSecond(now: date(2024, 3, 13, 2, 0)), 0)
    }

    func testOvernightShift_earningsAreZero() {
        let engine = SalaryEngine(config: makeNightShift(), calendar: calendar)
        let now = date(2024, 3, 13, 2, 0)
        XCTAssertEqual(engine.todayEarnings(now: now), 0, "无效班次不产生收入，避免误导")
    }

    // MARK: - 状态机

    func testDayState_allStates() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 13, 8, 0)), .beforeWork)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 13, 10, 0)), .working)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 13, 12, 30)), .lunch)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 13, 20, 0)), .afterWork)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 16, 10, 0)), .dayOff, "周六应是休息日")
    }

    // MARK: - 进度与金额一致性

    func testProgress_matchesEarningsRatio() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        let now = date(2024, 3, 13, 14, 0) // 下午2点，已工作4小时/共8小时 = 0.5
        XCTAssertEqual(engine.progress(now: now), 0.5, accuracy: 0.001)
        // 已赚 应 = 进度 × 预计今日总额
        let expected = engine.progress(now: now) * engine.dailySalary(now: now)
        XCTAssertEqual(engine.todayEarnings(now: now), expected, accuracy: 1e-6)
    }

    func testProgress_clampedTo1AfterWork() {
        let engine = SalaryEngine(config: makeConfig(), calendar: calendar)
        XCTAssertEqual(engine.progress(now: date(2024, 3, 13, 20, 0)), 1.0)
    }

    // MARK: - 时区无关性（修复 #2）

    /// 同一份配置（分钟制）在不同时区解读出的工时应一致。
    func testTimezoneIndependence_dailyWorkSecondsStable() {
        let config = makeConfig()
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!

        let e1 = SalaryEngine(config: config, calendar: tokyo)
        let e2 = SalaryEngine(config: config, calendar: newYork)
        XCTAssertEqual(e1.dailyWorkSeconds, e2.dailyWorkSeconds, "工时不应随时区漂移")
        XCTAssertEqual(e1.dailyWorkSeconds, 8 * 3600)
    }

    // MARK: - Codable（分钟制持久化）

    func testConfigCodableRoundtrip() throws {
        let config = makeConfig(monthlySalary: 12345)
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SalaryConfig.self, from: data)
        XCTAssertEqual(config, decoded)
        XCTAssertEqual(decoded.workStartMinutes, 9 * 60)
        XCTAssertEqual(decoded.workEndMinutes, 18 * 60)
    }

    // MARK: - 节假日接口（调休补班 > 法定节假日 > 按星期几）

    func testHoliday_legalHolidayNotWorkday() {
        // 2024-05-01 劳动节（周三，本是工作日），设为法定节假日 → 不计薪
        let holiday = HolidayConfig(date: date(2024, 5, 1), name: "劳动节")
        let engine = SalaryEngine(config: makeConfig(), holidays: [holiday], calendar: calendar)
        XCTAssertFalse(engine.isWorkday(date(2024, 5, 1)), "法定节假日不应是工作日")
        XCTAssertEqual(engine.todayEarnings(now: date(2024, 5, 1, 14, 0)), 0, "节假日收入为0")
    }

    func testHoliday_makeupWorkdayCountsAsWork() {
        // 2024-05-11 周六，调休补班 → 计薪
        let makeup = HolidayConfig(date: date(2024, 5, 11), name: "劳动节调休", isWorkday: true)
        let engine = SalaryEngine(config: makeConfig(), holidays: [makeup], calendar: calendar)
        XCTAssertTrue(engine.isWorkday(date(2024, 5, 11)), "调休补班应算工作日")
        XCTAssertGreaterThan(engine.todayEarnings(now: date(2024, 5, 11, 20, 0)), 0, "调休补班应计薪")
    }

    func testHoliday_emptyFallsBackToWeekday() {
        // 无节假日数据时退化为按星期几（向后兼容）
        let engine = SalaryEngine(config: makeConfig(), holidays: [], calendar: calendar)
        XCTAssertTrue(engine.isWorkday(date(2024, 5, 1)), "无节假日数据时周三仍是工作日")
        XCTAssertFalse(engine.isWorkday(date(2024, 5, 11)), "无节假日数据时周六是休息日")
    }

    func testHolidayConfigCodableRoundtrip() throws {
        let h = HolidayConfig(date: date(2024, 5, 1), name: "劳动节", isWorkday: false)
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(HolidayConfig.self, from: data)
        XCTAssertEqual(h, decoded)
    }

    // MARK: - 2026 内置真实数据

    /// 用上海时区日历构造引擎，与 HolidayData 内部时区一致。
    private func engine2026() -> SalaryEngine {
        SalaryEngine(config: makeConfig(), holidays: HolidayData.holidays(year: 2026), calendar: calendar)
    }

    func testData2026_springFestivalNotWorkday() {
        let engine = engine2026()
        // 2026-02-16 周一，春节假期 → 不计薪
        XCTAssertFalse(engine.isWorkday(date(2026, 2, 16)), "春节假期不应是工作日")
        XCTAssertEqual(engine.todayEarnings(now: date(2026, 2, 16, 14, 0)), 0)
    }

    func testData2026_makeupWorkdayCounts() {
        let engine = engine2026()
        // 2026-02-28 周六，春节调休补班 → 计薪
        XCTAssertTrue(engine.isWorkday(date(2026, 2, 28)), "2/28 调休补班应是工作日")
        XCTAssertGreaterThan(engine.todayEarnings(now: date(2026, 2, 28, 20, 0)), 0)
        // 2026-10-10 周六，国庆调休补班
        XCTAssertTrue(engine.isWorkday(date(2026, 10, 10)), "10/10 调休补班应是工作日")
    }

    func testData2026_nationalDayHoliday() {
        let engine = engine2026()
        // 2026-10-01 周四，国庆 → 不计薪
        XCTAssertFalse(engine.isWorkday(date(2026, 10, 1)), "国庆假期不应是工作日")
    }

    func testData2026_normalWorkdayUnaffected() {
        let engine = engine2026()
        // 2026-03-04 周三，普通工作日 → 正常计薪
        XCTAssertTrue(engine.isWorkday(date(2026, 3, 4)))
        XCTAssertGreaterThan(engine.todayEarnings(now: date(2026, 3, 4, 20, 0)), 0)
    }

    func testData2026_unknownYearIsEmpty() {
        XCTAssertTrue(HolidayData.holidays(year: 2099).isEmpty, "无数据年份应返回空，退化为按星期几")
    }

    // MARK: - 全天模式（24×7 平摊）

    private func allDayConfig(monthlySalary: Double = 30000) -> SalaryConfig {
        SalaryConfig(monthlySalary: monthlySalary, earningMode: .allDay)
    }

    func testAllDay_everyDayIsWorkday() {
        let engine = SalaryEngine(config: allDayConfig(), calendar: calendar)
        XCTAssertTrue(engine.isWorkday(date(2024, 3, 16)), "全天模式周六也算赚钱日")
        XCTAssertTrue(engine.isWorkday(date(2024, 3, 17)), "全天模式周日也算赚钱日")
    }

    func testAllDay_dailyWorkSecondsIsFullDay() {
        let engine = SalaryEngine(config: allDayConfig(), calendar: calendar)
        XCTAssertEqual(engine.dailyWorkSeconds, 86400, "全天模式每日 86400 秒")
    }

    func testAllDay_dailySalaryDividesByCalendarDays() {
        let engine = SalaryEngine(config: allDayConfig(monthlySalary: 31000), calendar: calendar)
        // 2024年3月31天 → 日薪 = 31000/31 = 1000
        XCTAssertEqual(engine.dailySalary(now: date(2024, 3, 15)), 1000, accuracy: 1e-6)
    }

    func testAllDay_secondsWorkedFromMidnight() {
        let engine = SalaryEngine(config: allDayConfig(), calendar: calendar)
        // 中午12点 = 从0点起 43200 秒
        XCTAssertEqual(engine.secondsWorkedToday(now: date(2024, 3, 15, 12, 0)), 43200, accuracy: 1)
    }

    func testAllDay_earningsNeverZeroOnWeekend() {
        let engine = SalaryEngine(config: allDayConfig(), calendar: calendar)
        // 周六中午也在赚钱
        XCTAssertGreaterThan(engine.todayEarnings(now: date(2024, 3, 16, 12, 0)), 0)
    }

    func testAllDay_stateAlwaysWorking() {
        let engine = SalaryEngine(config: allDayConfig(), calendar: calendar)
        XCTAssertEqual(engine.dayState(now: date(2024, 3, 16, 3, 0)), .working, "全天模式凌晨也是工作中")
    }

    func testAllDay_fullDayEqualsDailySalary() {
        let engine = SalaryEngine(config: allDayConfig(monthlySalary: 31000), calendar: calendar)
        // 一天接近结束（23:59）今日收入 ≈ 日薪 1000（差不到 1 分钟的钱）
        XCTAssertEqual(engine.todayEarnings(now: date(2024, 3, 15, 23, 59)), 1000, accuracy: 1.0)
    }

    func testEarningModeCodableRoundtrip() throws {
        let config = allDayConfig()
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SalaryConfig.self, from: data)
        XCTAssertEqual(decoded.earningMode, .allDay)
    }

    // MARK: - 节假日数据覆盖（跨年防退化）

    func testHolidayData_2026_hasData() {
        XCTAssertTrue(HolidayData.hasData(year: 2026), "2026 应已内置节假日数据")
    }

    func testHolidayData_2027_2028_hasData() {
        // 2027 / 2028 已内置（节日日期来自农历换算，放假与调休为推算，见 HolidayData 注释）。
        XCTAssertTrue(HolidayData.hasData(year: 2027), "2027 应已内置")
        XCTAssertTrue(HolidayData.hasData(year: 2028), "2028 应已内置")
    }

    func testHolidayData_2029_stillMissing() {
        // 留一道「还没扩到哪一年」的判据：2029 未内置，UI 该提示。
        XCTAssertFalse(HolidayData.hasData(year: 2029), "2029 未内置，应报告缺失以便 UI 提示")
    }

    /// 把「哪些年份还是推算的」变成一条会说话的测试。
    ///
    /// 它**故意不失败** —— 推算数据是有意为之，不是 bug。
    /// 但它会在测试输出里印出来，而且当 2027 被换成官方数据后，
    /// 下面 `extrapolatedYears` 的期望值必须跟着改 —— 改的时候你就重新想了一遍。
    func testHolidayData_extrapolatedYearsAreDeclared() {
        // 每个内置年份都必须在 confidence 里表态，不能有「有数据但没说可信度」的年份。
        for year in HolidayData.supportedYears {
            XCTAssertNotNil(HolidayData.confidence[year],
                            "\(year) 有节假日数据，但没在 confidence 里说明是官方还是外推")
        }
        // 反过来：声明了可信度却没数据的年份，也是漂移。
        for year in HolidayData.confidence.keys {
            XCTAssertTrue(HolidayData.supportedYears.contains(year),
                          "\(year) 在 confidence 里但 supportedYears 没有")
        }

        // 这份清单是「欠的债」。官方数据换进来之后必须变短，否则这条会红提醒你更新。
        XCTAssertEqual(
            HolidayData.extrapolatedYears, [2027, 2028],
            """
            仍是外推的年份变了。
            - 如果你刚把某年换成国务院正式安排：把该年的 confidence 改成 .official，并缩短这个数组。
            - 如果这条突然多出年份：说明有人加了数据但没标可信度。
            """
        )
    }

    func testHolidayData_supportedYearsMatchesHolidays() {
        // supportedYears 与实际有数据的年份必须一致，否则提示会撒谎。
        for year in HolidayData.supportedYears {
            XCTAssertFalse(HolidayData.holidays(year: year).isEmpty,
                           "\(year) 声明已支持但数据为空")
        }
    }

    /// 农历节日日期必须能对上——这是 2027/2028 数据里唯一「准」的那部分，不能错。
    ///
    /// 基准值用系统农历逐日扫描得出，且已用 2026 年校验过方法本身：
    /// 同一套算法算 2026 得到的春节 2/17、端午 6/19、中秋 9/25 与国务院已发布安排一致。
    private func assertFestival(
        year: Int, month: Int, day: Int, name: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let target = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        let configs = HolidayData.holidays(year: year)
        let hit = configs.first { calendar.isDate($0.date, inSameDayAs: target) && !$0.isWorkday }
        XCTAssertNotNil(hit, "\(year)-\(month)-\(day) 应是\(name)放假日", file: file, line: line)
        XCTAssertEqual(hit?.name.contains(name) ?? false, true,
                       "\(year)-\(month)-\(day) 的节日名应包含「\(name)」，实际 \(hit?.name ?? "nil")",
                       file: file, line: line)
    }

    func testHolidayData_2027_festivalDates() {
        // 正月初一 2027-02-06、五月初五 06-09、八月十五 09-15
        assertFestival(year: 2027, month: 2, day: 6, name: "春节")
        assertFestival(year: 2027, month: 6, day: 9, name: "端午")
        assertFestival(year: 2027, month: 9, day: 15, name: "中秋")
    }

    func testHolidayData_2028_festivalDates() {
        // 正月初一 2028-01-26、五月初五 05-28、八月十五 10-03
        assertFestival(year: 2028, month: 1, day: 26, name: "春节")
        assertFestival(year: 2028, month: 5, day: 28, name: "端午")
        assertFestival(year: 2028, month: 10, day: 3, name: "中秋")
    }

    func testHolidayData_noDuplicateDays() {
        // 同一天既标放假又标补班，会让「今天算不算上班」自相矛盾。
        for year in HolidayData.supportedYears {
            var seen: [Date] = []
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
            for c in HolidayData.holidays(year: year) {
                let day = calendar.startOfDay(for: c.date)
                XCTAssertFalse(seen.contains(day), "\(year) 有重复日期：\(day)")
                seen.append(day)
            }
        }
    }

    // MARK: - 实物换算（上瘾钩子）

    func testMoneyEquivalent_tooSmall_returnsNil() {
        // 不足一杯奶茶（18 元）不显示，避免「0 杯」。
        XCTAssertNil(MoneyEquivalent.describe(5))
        XCTAssertNil(MoneyEquivalent.describe(0))
    }

    func testMoneyEquivalent_picksMostExpensiveReasonableItem() {
        // 选「数量 1...99 的最贵实物」：54 元 → 1 场电影（50/场），而非 3 杯奶茶。
        let result = MoneyEquivalent.describe(54)
        XCTAssertEqual(result?.text, "≈ 1 场电影")
    }

    func testMoneyEquivalent_milkTeaWhenOnlyMilkTeaFits() {
        // 18...29 元只够奶茶（不足一顿外卖 30）。
        let result = MoneyEquivalent.describe(20)
        XCTAssertEqual(result?.text, "≈ 1 杯奶茶")
    }

    func testMoneyEquivalent_largeAmount_usesExpensiveItem() {
        // 大额时选更贵的实物，避免「2000 杯奶茶」这类夸张数字。
        let result = MoneyEquivalent.describe(3000)
        XCTAssertEqual(result?.text, "≈ 20 顿火锅") // 3000/150 = 20
    }

    func testMoneyEquivalent_hugeAmount_fallsBackToMostExpensive() {
        // 金额极大（所有实物数量都 >99）：用最贵实物兜底，不退回奶茶。
        let result = MoneyEquivalent.describe(50000)
        XCTAssertEqual(result?.icon, "flame.fill") // 火锅，而非奶茶
    }

    // MARK: - 数据持久性 & 向后兼容（更新不丢数据的保证）

    /// 模拟「旧版本存的 JSON」——没有 earningMode 字段。
    /// 新版本必须能正确读出，并默认工作时段，绝不解码失败导致配置清空。
    func testBackwardCompat_oldDataWithoutEarningMode() throws {
        let oldJSON = """
        {
          "monthlySalary": 8888,
          "workStartMinutes": 540,
          "workEndMinutes": 1080,
          "lunchEnabled": true,
          "lunchStartMinutes": 720,
          "lunchEndMinutes": 780,
          "workDays": [2, 3, 4, 5, 6]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(SalaryConfig.self, from: oldJSON)
        XCTAssertEqual(decoded.monthlySalary, 8888, "旧数据的月薪必须保留")
        XCTAssertEqual(decoded.earningMode, .workHours, "缺失字段应默认工作时段，而非崩溃/清空")
        XCTAssertEqual(decoded.workStartMinutes, 540)
        XCTAssertEqual(decoded.workDays, [2, 3, 4, 5, 6])
    }

    /// 经由 UserDefaults 存取一轮，配置完整无损（模拟版本更新后重新读取）。
    func testPersistence_roundtripThroughUserDefaults() {
        let suite = UserDefaults(suiteName: "test.persistence.\(UUID().uuidString)")!
        var config = makeConfig(monthlySalary: 12345)
        config.earningMode = .allDay
        config.saveShared(to: suite)

        let loaded = SalaryConfig.loadShared(from: suite)
        XCTAssertEqual(loaded.monthlySalary, 12345)
        XCTAssertEqual(loaded.earningMode, .allDay)
        XCTAssertEqual(loaded, config, "存取一轮后配置应完全一致")
    }

    /// 存储为空时（首次安装/读取失败）返回默认配置，不崩溃。
    func testPersistence_emptyReturnsDefault() {
        let suite = UserDefaults(suiteName: "test.empty.\(UUID().uuidString)")!
        let loaded = SalaryConfig.loadShared(from: suite)
        XCTAssertEqual(loaded, SalaryConfig(), "无数据时应返回默认配置")
    }
}
