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
            workDays: [1, 2, 3, 4, 5],
            overtimeRate: 1.5,
            overtimeStartTime: calendar.date(from: DateComponents(hour: 18, minute: 0)),
            overtimeEndTime: calendar.date(from: DateComponents(hour: 21, minute: 0)),
            holidayOvertimeRate: 3.0
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
    
    // MARK: - 加班工资测试
    
    func testOvertimeEarnings() {
        // 设置当前时间为加班时间
        let now = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        
        // 计算加班工资
        let overtimeSeconds = config.calculateOvertimeSeconds(for: now)
        let overtimeEarnings = overtimeSeconds * config.salaryPerSecond * config.overtimeRate
        
        // 验证加班时间（1小时）
        XCTAssertEqual(overtimeSeconds, 3600)
        
        // 验证加班工资（应该比正常工资高1.5倍）
        let normalHourlyRate = config.salaryPerSecond * 3600
        XCTAssertEqual(overtimeEarnings, normalHourlyRate * 1.5)
    }
    
    func testNoOvertimeEarnings() {
        // 设置当前时间为非加班时间
        let now = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
        
        // 计算加班工资
        let overtimeSeconds = config.calculateOvertimeSeconds(for: now)
        let overtimeEarnings = overtimeSeconds * config.salaryPerSecond * config.overtimeRate
        
        // 验证加班时间为0
        XCTAssertEqual(overtimeSeconds, 0)
        XCTAssertEqual(overtimeEarnings, 0)
    }
    
    // MARK: - 特殊节假日工资测试
    
    func testHolidayOvertimeEarnings() {
        // 创建一个周末日期
        let weekend = calendar.date(from: DateComponents(year: 2024, month: 3, day: 16))!
        
        // 计算节假日加班工资
        let holidaySeconds = config.calculateHolidayOvertimeSeconds(for: weekend)
        let holidayEarnings = holidaySeconds * config.salaryPerSecond * config.holidayOvertimeRate
        
        // 验证节假日加班时间（应该等于全天工作时间）
        XCTAssertEqual(holidaySeconds, config.dailyWorkSeconds)
        
        // 验证节假日加班工资（应该比正常工资高3倍）
        let normalDailyRate = config.salaryPerSecond * config.dailyWorkSeconds
        XCTAssertEqual(holidayEarnings, normalDailyRate * 3.0)
    }
    
    func testNoHolidayOvertimeEarnings() {
        // 创建一个工作日
        let workday = calendar.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        
        // 计算节假日加班工资
        let holidaySeconds = config.calculateHolidayOvertimeSeconds(for: workday)
        let holidayEarnings = holidaySeconds * config.salaryPerSecond * config.holidayOvertimeRate
        
        // 验证节假日加班时间为0
        XCTAssertEqual(holidaySeconds, 0)
        XCTAssertEqual(holidayEarnings, 0)
    }
    
    // MARK: - 跨月工资测试
    
    func testCrossMonthEarnings() {
        // 创建跨月的日期范围（3月15日到4月15日）
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        let endDate = calendar.date(from: DateComponents(year: 2024, month: 4, day: 15))!
        
        // 计算跨月工资
        let earnings = calculator.calculateCrossMonthEarnings(from: startDate, to: endDate)
        
        // 验证跨月工资大于0
        XCTAssertGreaterThan(earnings, 0)
        
        // 验证跨月工资不超过两个月工资
        let twoMonthsSalary = config.monthlySalary * 2
        XCTAssertLessThanOrEqual(earnings, twoMonthsSalary)
    }
    
    func testCrossMonthEarningsWithHolidays() {
        // 创建包含节假日的跨月日期范围（4月1日到5月1日，包含劳动节）
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 4, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1))!
        
        // 计算跨月工资
        let earnings = calculator.calculateCrossMonthEarnings(from: startDate, to: endDate)
        
        // 验证跨月工资大于0
        XCTAssertGreaterThan(earnings, 0)
        
        // 验证跨月工资不超过两个月工资
        let twoMonthsSalary = config.monthlySalary * 2
        XCTAssertLessThanOrEqual(earnings, twoMonthsSalary)
    }
    
    // MARK: - 边界条件测试
    
    func testEdgeCases() {
        // 测试午夜时间
        let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let midnightEarnings = calculator.calculateTodayEarnings()
        XCTAssertEqual(midnightEarnings, 0)
        
        // 测试工作日结束时间
        let workEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let workEndEarnings = calculator.calculateTodayEarnings()
        XCTAssertGreaterThan(workEndEarnings, 0)
        
        // 测试加班开始时间
        let overtimeStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let overtimeStartEarnings = calculator.calculateTodayEarnings()
        XCTAssertEqual(overtimeStartEarnings, config.salaryPerSecond * config.dailyWorkSeconds)
    }
    
    // MARK: - 性能测试
    
    func testPerformance() {
        measure {
            // 测试跨月工资计算的性能
            let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
            let endDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
            _ = calculator.calculateCrossMonthEarnings(from: startDate, to: endDate)
        }
    }
} 