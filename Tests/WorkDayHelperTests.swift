import XCTest
@testable import ios_salary_count

final class WorkDayHelperTests: XCTestCase {
    var config: SalaryConfig!
    var holidays: [HolidayConfig]!
    var calendar: Calendar!
    var testDate: Date! // 固定的测试日期
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        
        // 设置固定的测试日期（2024年3月13日，星期三）
        testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        
        config = SalaryConfig(
            monthlySalary: 3000,
            workStartTime: calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? testDate,
            workEndTime: calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? testDate,
            lunchStartTime: calendar.date(from: DateComponents(hour: 12, minute: 0)),
            lunchEndTime: calendar.date(from: DateComponents(hour: 13, minute: 0)),
            workDays: [1, 2, 3, 4, 5] // 周一至周五
        )
        
        // 设置测试用的节假日数据
        holidays = [
            // 妇女节
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!,
                name: "妇女节"
            ),
            // 调休工作日
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 9))!,
                name: "春节调休",
                isWorkday: true
            )
        ]
    }
    
    override func tearDown() {
        config = nil
        holidays = nil
        calendar = nil
        testDate = nil
        super.tearDown()
    }
    
    // 测试工作状态判断
    func testWorkStatus() {
        // 测试工作时间前（8:30）
        let beforeWork = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: testDate)!
        let beforeWorkStatus = WorkDayHelper.getWorkStatus(for: beforeWork, config: config, holidays: holidays)
        XCTAssertEqual(beforeWorkStatus, .beforeWork, "8:30应该是未开始工作状态")
        
        // 测试工作时间（10:30）
        let working = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: testDate)!
        let workingStatus = WorkDayHelper.getWorkStatus(for: working, config: config, holidays: holidays)
        XCTAssertEqual(workingStatus, .working, "10:30应该是工作中状态")
        
        // 测试午休时间（12:30）
        let lunchBreak = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: testDate)!
        let lunchBreakStatus = WorkDayHelper.getWorkStatus(for: lunchBreak, config: config, holidays: holidays)
        XCTAssertEqual(lunchBreakStatus, .lunchBreak, "12:30应该是午休中状态")
        
        // 测试下班后（18:30）
        let afterWork = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: testDate)!
        let afterWorkStatus = WorkDayHelper.getWorkStatus(for: afterWork, config: config, holidays: holidays)
        XCTAssertEqual(afterWorkStatus, .afterWork, "18:30应该是已下班状态")
        
        // 测试边界条件：工作开始时间（9:00）
        let workStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: testDate)!
        let workStartStatus = WorkDayHelper.getWorkStatus(for: workStart, config: config, holidays: holidays)
        XCTAssertEqual(workStartStatus, .working, "9:00应该是工作中状态")
        
        // 测试边界条件：午休开始时间（12:00）
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: testDate)!
        let lunchStartStatus = WorkDayHelper.getWorkStatus(for: lunchStart, config: config, holidays: holidays)
        XCTAssertEqual(lunchStartStatus, .lunchBreak, "12:00应该是午休中状态")
        
        // 测试边界条件：午休结束时间（13:00）
        let lunchEnd = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: testDate)!
        let lunchEndStatus = WorkDayHelper.getWorkStatus(for: lunchEnd, config: config, holidays: holidays)
        XCTAssertEqual(lunchEndStatus, .working, "13:00应该是工作中状态")
        
        // 测试边界条件：工作结束时间（18:00）
        let workEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: testDate)!
        let workEndStatus = WorkDayHelper.getWorkStatus(for: workEnd, config: config, holidays: holidays)
        XCTAssertEqual(workEndStatus, .afterWork, "18:00应该是已下班状态")
        
        // 测试边界条件：午夜时间（0:00）
        let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: testDate)!
        let midnightStatus = WorkDayHelper.getWorkStatus(for: midnight, config: config, holidays: holidays)
        XCTAssertEqual(midnightStatus, .beforeWork, "0:00应该是未开始工作状态")
        
        // 测试边界条件：没有午休时间的配置
        let noLunchConfig = SalaryConfig(
            monthlySalary: config.monthlySalary,
            workStartTime: config.workStartTime,
            workEndTime: config.workEndTime,
            lunchStartTime: nil,
            lunchEndTime: nil,
            workDays: config.workDays
        )
        let lunchTimeStatus = WorkDayHelper.getWorkStatus(for: lunchBreak, config: noLunchConfig, holidays: holidays)
        XCTAssertEqual(lunchTimeStatus, .working, "没有午休时间时，12:30应该是工作中状态")
    }
    
    // 测试工作日判断
    func testIsWorkday() {
        // 测试普通工作日（星期三）
        let isWorkday = WorkDayHelper.isWorkday(testDate, config: config, holidays: holidays)
        XCTAssertTrue(isWorkday, "星期三应该是工作日")
        
        // 测试周末（星期六）
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let isWeekend = WorkDayHelper.isWorkday(weekend, config: config, holidays: holidays)
        XCTAssertFalse(isWeekend, "星期六不应该被识别为工作日")
        
        // 测试节假日（妇女节）
        let holiday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!
        let isHoliday = WorkDayHelper.isWorkday(holiday, config: config, holidays: holidays)
        XCTAssertFalse(isHoliday, "节假日不应该被识别为工作日")
        
        // 测试调休工作日
        let workday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 9))!
        let isWorkdayHoliday = WorkDayHelper.isWorkday(workday, config: config, holidays: holidays)
        XCTAssertTrue(isWorkdayHoliday, "调休工作日应该被识别为工作日")
        
        // 测试边界条件：自定义工作日（周二到周六）
        let customConfig = SalaryConfig(
            monthlySalary: config.monthlySalary,
            workStartTime: config.workStartTime,
            workEndTime: config.workEndTime,
            lunchStartTime: config.lunchStartTime,
            lunchEndTime: config.lunchEndTime,
            workDays: [2, 3, 4, 5, 6]
        )
        let saturday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let isSaturday = WorkDayHelper.isWorkday(saturday, config: customConfig, holidays: holidays)
        XCTAssertTrue(isSaturday, "在自定义工作日配置下，星期六应该被识别为工作日")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let isWorkdayWithEmptyHolidays = WorkDayHelper.isWorkday(testDate, config: config, holidays: emptyHolidays)
        XCTAssertTrue(isWorkdayWithEmptyHolidays, "空节假日列表下，星期三应该被识别为工作日")
    }
    
    // 测试获取下一个工作日
    func testGetNextWorkday() {
        // 从普通工作日获取下一个工作日
        let nextWorkday = WorkDayHelper.getNextWorkday(from: testDate, config: config, holidays: holidays)
        XCTAssertNotNil(nextWorkday, "应该能找到下一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(nextWorkday!, config: config, holidays: holidays), "获取的下一个日期应该是工作日")
        
        // 从周末获取下一个工作日
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let nextWorkdayFromWeekend = WorkDayHelper.getNextWorkday(from: weekend, config: config, holidays: holidays)
        XCTAssertNotNil(nextWorkdayFromWeekend, "从周末应该能找到下一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(nextWorkdayFromWeekend!, config: config, holidays: holidays), "从周末获取的下一个日期应该是工作日")
        
        // 从节假日获取下一个工作日
        let holiday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!
        let nextWorkdayFromHoliday = WorkDayHelper.getNextWorkday(from: holiday, config: config, holidays: holidays)
        XCTAssertNotNil(nextWorkdayFromHoliday, "从节假日应该能找到下一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(nextWorkdayFromHoliday!, config: config, holidays: holidays), "从节假日获取的下一个日期应该是工作日")
        XCTAssertEqual(calendar.component(.day, from: nextWorkdayFromHoliday!), 9, "从妇女节获取的下一个工作日应该是3月9日（调休工作日）")
    }
    
    // 测试获取上一个工作日
    func testGetPreviousWorkday() {
        // 从普通工作日获取上一个工作日
        let previousWorkday = WorkDayHelper.getPreviousWorkday(from: testDate, config: config, holidays: holidays)
        XCTAssertNotNil(previousWorkday, "应该能找到上一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(previousWorkday!, config: config, holidays: holidays), "获取的上一个日期应该是工作日")
        
        // 从周末获取上一个工作日
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let previousWorkdayFromWeekend = WorkDayHelper.getPreviousWorkday(from: weekend, config: config, holidays: holidays)
        XCTAssertNotNil(previousWorkdayFromWeekend, "从周末应该能找到上一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(previousWorkdayFromWeekend!, config: config, holidays: holidays), "从周末获取的上一个日期应该是工作日")
        
        // 从节假日获取上一个工作日
        let holiday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!
        let previousWorkdayFromHoliday = WorkDayHelper.getPreviousWorkday(from: holiday, config: config, holidays: holidays)
        XCTAssertNotNil(previousWorkdayFromHoliday, "从节假日应该能找到上一个工作日")
        XCTAssertTrue(WorkDayHelper.isWorkday(previousWorkdayFromHoliday!, config: config, holidays: holidays), "从节假日获取的上一个日期应该是工作日")
        XCTAssertEqual(calendar.component(.day, from: previousWorkdayFromHoliday!), 7, "从妇女节获取的上一个工作日应该是3月7日")
    }
} 