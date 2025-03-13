import XCTest
@testable import ios_salary_count

final class HolidayHelperTests: XCTestCase {
    var holidays: [HolidayConfig]!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        let now = Date()
        
        // 添加一些节假日
        holidays = [
            // 元旦
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!,
                name: "元旦"
            ),
            // 春节
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 2, day: 10))!,
                name: "春节"
            ),
            // 调休工作日
            HolidayConfig(
                date: calendar.date(from: DateComponents(year: 2024, month: 2, day: 4))!,
                name: "春节调休",
                isWorkday: true
            )
        ]
    }
    
    override func tearDown() {
        holidays = nil
        calendar = nil
        super.tearDown()
    }
    
    // 测试节假日判断
    func testIsHoliday() {
        let today = calendar.startOfDay(for: Date())
        
        // 测试当前日期
        let isHoliday = HolidayHelper.isHoliday(today, holidays: holidays)
        XCTAssertFalse(isHoliday, "当前日期不应该被识别为节假日")
        
        // 测试元旦
        let newYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let isNewYear = HolidayHelper.isHoliday(newYear, holidays: holidays)
        XCTAssertTrue(isNewYear, "元旦应该被识别为节假日")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let isHolidayWithEmpty = HolidayHelper.isHoliday(today, holidays: emptyHolidays)
        XCTAssertFalse(isHolidayWithEmpty, "空节假日列表不应该识别为节假日")
        
        // 测试边界条件：无效日期
        let invalidDate = calendar.date(byAdding: .year, value: -1, to: today)!
        let isInvalidHoliday = HolidayHelper.isHoliday(invalidDate, holidays: holidays)
        XCTAssertFalse(isInvalidHoliday, "无效日期不应该被识别为节假日")
    }
    
    // 测试调休工作日判断
    func testIsWorkday() {
        let today = calendar.startOfDay(for: Date())
        
        // 测试调休工作日
        let workday = calendar.date(from: DateComponents(year: 2024, month: 2, day: 4))!
        let isWorkday = HolidayHelper.isWorkday(workday, holidays: holidays)
        XCTAssertTrue(isWorkday, "调休工作日应该被识别为工作日")
        
        // 测试普通工作日
        let normalWorkday = calendar.date(from: DateComponents(year: 2024, month: 2, day: 5))!
        let isNormalWorkday = HolidayHelper.isWorkday(normalWorkday, holidays: holidays)
        XCTAssertFalse(isNormalWorkday, "普通工作日不应该被识别为调休工作日")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let isWorkdayWithEmpty = HolidayHelper.isWorkday(today, holidays: emptyHolidays)
        XCTAssertFalse(isWorkdayWithEmpty, "空节假日列表不应该识别为调休工作日")
        
        // 测试边界条件：无效日期
        let invalidDate = calendar.date(byAdding: .year, value: -1, to: today)!
        let isInvalidWorkday = HolidayHelper.isWorkday(invalidDate, holidays: holidays)
        XCTAssertFalse(isInvalidWorkday, "无效日期不应该被识别为调休工作日")
    }
    
    // 测试获取下一个节假日
    func testGetNextHoliday() {
        let today = calendar.startOfDay(for: Date())
        
        // 获取下一个节假日
        let nextHoliday = HolidayHelper.getNextHoliday(from: today, holidays: holidays)
        XCTAssertNotNil(nextHoliday, "应该能找到下一个节假日")
        XCTAssertEqual(nextHoliday?.name, "元旦", "下一个节假日应该是元旦")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let nextHolidayWithEmpty = HolidayHelper.getNextHoliday(from: today, holidays: emptyHolidays)
        XCTAssertNil(nextHolidayWithEmpty, "空节假日列表不应该返回下一个节假日")
        
        // 测试边界条件：当前日期在最后一个节假日之后
        let lastHoliday = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let nextHolidayAfterLast = HolidayHelper.getNextHoliday(from: lastHoliday, holidays: holidays)
        XCTAssertNil(nextHolidayAfterLast, "最后一个节假日之后不应该有下一个节假日")
    }
    
    // 测试获取上一个节假日
    func testGetPreviousHoliday() {
        let today = calendar.startOfDay(for: Date())
        
        // 获取上一个节假日
        let previousHoliday = HolidayHelper.getPreviousHoliday(from: today, holidays: holidays)
        XCTAssertNil(previousHoliday, "当前不应该有上一个节假日")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let previousHolidayWithEmpty = HolidayHelper.getPreviousHoliday(from: today, holidays: emptyHolidays)
        XCTAssertNil(previousHolidayWithEmpty, "空节假日列表不应该返回上一个节假日")
        
        // 测试边界条件：当前日期在第一个节假日之前
        let firstHoliday = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31))!
        let previousHolidayBeforeFirst = HolidayHelper.getPreviousHoliday(from: firstHoliday, holidays: holidays)
        XCTAssertNil(previousHolidayBeforeFirst, "第一个节假日之前不应该有上一个节假日")
    }
    
    // 测试计算距离节假日的天数
    func testHolidayDays() {
        let today = calendar.startOfDay(for: Date())
        
        // 计算距离下一个节假日的天数
        let daysUntilNext = HolidayHelper.getDaysUntilNextHoliday(from: today, holidays: holidays)
        XCTAssertNotNil(daysUntilNext, "应该能计算距离下一个节假日的天数")
        XCTAssertGreaterThan(daysUntilNext ?? 0, 0, "距离下一个节假日的天数应该大于0")
        
        // 计算距离上一个节假日的天数
        let daysSinceLast = HolidayHelper.getDaysSinceLastHoliday(from: today, holidays: holidays)
        XCTAssertNil(daysSinceLast, "当前不应该有上一个节假日")
        
        // 测试边界条件：空节假日列表
        let emptyHolidays: [HolidayConfig] = []
        let daysUntilNextWithEmpty = HolidayHelper.getDaysUntilNextHoliday(from: today, holidays: emptyHolidays)
        XCTAssertNil(daysUntilNextWithEmpty, "空节假日列表不应该计算距离下一个节假日的天数")
        
        // 测试边界条件：当前日期是节假日
        let newYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let daysUntilNextOnHoliday = HolidayHelper.getDaysUntilNextHoliday(from: newYear, holidays: holidays)
        XCTAssertEqual(daysUntilNextOnHoliday, 0, "当前日期是节假日时，距离下一个节假日的天数应该是0")
    }
} 