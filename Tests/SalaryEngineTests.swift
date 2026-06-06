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
}
