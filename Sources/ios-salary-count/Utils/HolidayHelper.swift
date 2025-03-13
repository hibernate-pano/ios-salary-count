import Foundation

class HolidayHelper {
    // 获取指定年份的节假日数据
    static func fetchHolidays(year: Int) async throws -> [HolidayConfig] {
        // TODO: 实现从网络获取节假日数据的逻辑
        // 这里先返回一些示例数据
        return [
            // 元旦
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!, name: "元旦"),
            // 春节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 10))!, name: "春节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 11))!, name: "春节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 12))!, name: "春节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 13))!, name: "春节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 14))!, name: "春节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 2, day: 15))!, name: "春节"),
            // 清明节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 4, day: 4))!, name: "清明节"),
            // 劳动节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 5, day: 1))!, name: "劳动节"),
            // 端午节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 6, day: 10))!, name: "端午节"),
            // 中秋节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 9, day: 15))!, name: "中秋节"),
            // 国庆节
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 10, day: 1))!, name: "国庆节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 10, day: 2))!, name: "国庆节"),
            HolidayConfig(date: Calendar.current.date(from: DateComponents(year: year, month: 10, day: 3))!, name: "国庆节")
        ]
    }
    
    // 获取下一个节假日
    static func getNextHoliday(from date: Date, holidays: [HolidayConfig]) -> HolidayConfig? {
        return holidays
            .filter { $0.date > date }
            .sorted { $0.date < $1.date }
            .first
    }
    
    // 获取上一个节假日
    static func getPreviousHoliday(from date: Date, holidays: [HolidayConfig]) -> HolidayConfig? {
        return holidays
            .filter { $0.date < date }
            .sorted { $0.date > $1.date }
            .first
    }
    
    // 获取距离下一个节假日的天数
    static func getDaysUntilNextHoliday(from date: Date, holidays: [HolidayConfig]) -> Int? {
        guard let nextHoliday = getNextHoliday(from: date, holidays: holidays) else {
            return nil
        }
        
        return Calendar.current.dateComponents([.day], from: date, to: nextHoliday.date).day
    }
    
    // 获取距离上一个节假日的天数
    static func getDaysSinceLastHoliday(from date: Date, holidays: [HolidayConfig]) -> Int? {
        guard let previousHoliday = getPreviousHoliday(from: date, holidays: holidays) else {
            return nil
        }
        
        return Calendar.current.dateComponents([.day], from: previousHoliday.date, to: date).day
    }
    
    // 获取指定日期是否为节假日
    static func isHoliday(_ date: Date, holidays: [HolidayConfig]) -> Bool {
        return HolidayConfig.isHoliday(date, holidays: holidays)
    }
    
    // 获取指定日期是否为调休工作日
    static func isWorkday(_ date: Date, holidays: [HolidayConfig]) -> Bool {
        return HolidayConfig.isWorkday(date, holidays: holidays)
    }
    
    // 获取指定日期的节假日名称
    static func getHolidayName(for date: Date, holidays: [HolidayConfig]) -> String? {
        return holidays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.name
    }
    
    // 获取指定日期的工作状态
    static func getWorkStatus(for date: Date, holidays: [HolidayConfig]) -> WorkStatus {
        if isWorkday(date, holidays: holidays) {
            return .workday
        }
        
        if isHoliday(date, holidays: holidays) {
            return .holiday
        }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 ? .weekend : .workday
    }
    
    // 获取指定日期的工作状态描述
    static func getWorkStatusDescription(for date: Date, holidays: [HolidayConfig]) -> String {
        let status = getWorkStatus(for: date, holidays: holidays)
        
        switch status {
        case .workday:
            if isWorkday(date, holidays: holidays) {
                return "调休工作日"
            }
            return "工作日"
        case .holiday:
            if let holidayName = getHolidayName(for: date, holidays: holidays) {
                return holidayName
            }
            return "节假日"
        case .weekend:
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekday == 1 ? "周日" : "周六"
        }
    }
} 