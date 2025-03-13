import XCTest
@testable import ios_salary_count

final class SalaryCalculatorTests: XCTestCase {
    var config: SalaryConfig!
    var calculator: SalaryCalculator!
    var calendar: Calendar!
    var holidays: [HolidayConfig]!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        
        // 设置固定的测试日期（2024年3月13日）
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        
        config = SalaryConfig(
            monthlySalary: 3000,
            workStartTime: calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? testDate,
            workEndTime: calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? testDate,
            lunchStartTime: calendar.date(from: DateComponents(hour: 12, minute: 0)),
            lunchEndTime: calendar.date(from: DateComponents(hour: 13, minute: 0)),
            workDays: [1, 2, 3, 4, 5]
        )
        
        // 设置测试用的节假日数据
        holidays = [
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!,
                name: "妇女节"
            ),
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 3, day: 9))!,
                name: "调休工作日",
                isWorkday: true
            )
        ]
        
        calculator = SalaryCalculator(config: config)
    }
    
    override func tearDown() {
        config = nil
        calculator = nil
        calendar = nil
        holidays = nil
        super.tearDown()
    }
    
    // 测试日工资计算
    func testDailySalary() {
        // 使用固定的测试日期
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        let components = calendar.dateComponents([.year, .month], from: testDate)
        guard let firstDay = calendar.date(from: components) else {
            XCTFail("无法获取本月第一天")
            return
        }
        
        // 计算2024年3月的工作日数（考虑节假日）
        var workDaysCount = 0
        var currentDate = firstDay
        let lastDay = calendar.date(from: DateComponents(year: 2024, month: 3, day: 31))!
        
        while !calendar.isDate(currentDate, inSameDayAs: lastDay) {
            if WorkDayHelper.isWorkday(currentDate, config: config, holidays: holidays) {
                workDaysCount += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // 2024年3月有21个工作日
        XCTAssertEqual(workDaysCount, 21, "2024年3月应该有21个工作日")
        
        let expectedDailySalary = config.monthlySalary / Double(workDaysCount)
        let actualDailySalary = calculator.calculateDailySalary()
        XCTAssertEqual(actualDailySalary, expectedDailySalary, accuracy: 0.01, "日工资计算不准确")
        
        // 测试边界条件：月薪为0
        let zeroConfig = SalaryConfig(
            monthlySalary: 0,
            workStartTime: config.workStartTime,
            workEndTime: config.workEndTime,
            lunchStartTime: config.lunchStartTime,
            lunchEndTime: config.lunchEndTime,
            workDays: config.workDays
        )
        let zeroCalculator = SalaryCalculator(config: zeroConfig)
        let zeroDailySalary = zeroCalculator.calculateDailySalary()
        XCTAssertEqual(zeroDailySalary, 0, "月薪为0时，日工资应该为0")
    }
    
    // 测试工作时间计算
    func testWorkTime() {
        // 使用固定的测试日期
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        
        // 获取工作时间范围
        let workStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: testDate)!
        let workEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: testDate)!
        
        // 测试工作时间范围
        XCTAssertLessThan(workStart, workEnd, "上班时间应该早于下班时间")
        
        // 计算工作秒数（不包括午休时间）
        let expectedWorkSeconds = 8 * 3600 // 9小时 - 1小时午休 = 8小时
        let actualWorkSeconds = calculator.calculateWorkSeconds()
        XCTAssertEqual(actualWorkSeconds, expectedWorkSeconds, "工作时间应该是8小时")
        
        // 测试午休时间
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: testDate)!
        let lunchEnd = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: testDate)!
        
        XCTAssertLessThan(lunchStart, lunchEnd, "午休开始时间应该早于结束时间")
        XCTAssertGreaterThan(lunchStart, workStart, "午休开始时间应该晚于上班时间")
        XCTAssertLessThan(lunchEnd, workEnd, "午休结束时间应该早于下班时间")
        
        // 测试边界条件：没有午休时间
        let noLunchConfig = SalaryConfig(
            monthlySalary: config.monthlySalary,
            workStartTime: config.workStartTime,
            workEndTime: config.workEndTime,
            lunchStartTime: nil,
            lunchEndTime: nil,
            workDays: config.workDays
        )
        let noLunchCalculator = SalaryCalculator(config: noLunchConfig)
        let noLunchWorkSeconds = noLunchCalculator.calculateWorkSeconds()
        XCTAssertEqual(noLunchWorkSeconds, 9 * 3600, "没有午休时，工作时间应该是9小时")
    }
    
    // 测试工作日判断
    func testWorkday() {
        // 使用固定的测试日期（2024年3月13日，星期三）
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        
        // 测试普通工作日
        let isWorkday = WorkDayHelper.isWorkday(testDate, config: config, holidays: holidays)
        XCTAssertTrue(isWorkday, "星期三应该是工作日")
        
        // 测试周末（2024年3月16日，星期六）
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let isWeekend = WorkDayHelper.isWorkday(weekend, config: config, holidays: holidays)
        XCTAssertFalse(isWeekend, "星期六不应该被识别为工作日")
        
        // 测试节假日（2024年3月8日，妇女节）
        let holiday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!
        let isHoliday = WorkDayHelper.isWorkday(holiday, config: config, holidays: holidays)
        XCTAssertFalse(isHoliday, "节假日不应该被识别为工作日")
        
        // 测试调休工作日（2024年3月9日）
        let workday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 9))!
        let isWorkdayHoliday = WorkDayHelper.isWorkday(workday, config: config, holidays: holidays)
        XCTAssertTrue(isWorkdayHoliday, "调休工作日应该被识别为工作日")
    }
    
    // 测试收入计算
    func testEarnings() {
        // 使用固定的测试日期（2024年3月13日，星期三）
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 13))!
        
        // 测试工作日收入
        let workdayEarnings = calculator.calculateEarnings(for: testDate)
        XCTAssertGreaterThan(workdayEarnings, 0, "工作日收入应该大于0")
        
        // 测试本月累计收入（到3月13日）
        let monthEarnings = calculator.calculateMonthEarnings()
        XCTAssertGreaterThanOrEqual(monthEarnings, workdayEarnings, "本月收入应该大于等于工作日收入")
        
        // 测试年度累计收入
        let yearEarnings = calculator.calculateYearEarnings()
        XCTAssertGreaterThanOrEqual(yearEarnings, monthEarnings, "年度收入应该大于等于本月收入")
        
        // 测试边界条件：非工作日收入（2024年3月16日，星期六）
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        let weekendEarnings = calculator.calculateEarnings(for: weekend)
        XCTAssertEqual(weekendEarnings, 0, "非工作日收入应该为0")
        
        // 测试边界条件：节假日收入（2024年3月8日，妇女节）
        let holiday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 8))!
        let holidayEarnings = calculator.calculateEarnings(for: holiday)
        XCTAssertEqual(holidayEarnings, 0, "节假日收入应该为0")
        
        // 测试边界条件：调休工作日收入（2024年3月9日）
        let workday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 9))!
        let workdayHolidayEarnings = calculator.calculateEarnings(for: workday)
        XCTAssertGreaterThan(workdayHolidayEarnings, 0, "调休工作日收入应该大于0")
    }
} 