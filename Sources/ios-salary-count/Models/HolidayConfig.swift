import Foundation
import SwiftData

@Model
final class HolidayConfig {
    // 节假日日期
    var date: Date
    
    // 节假日名称
    var name: String
    
    // 是否调休工作日
    var isWorkday: Bool
    
    // 创建时间
    var createdAt: Date
    
    init(date: Date, name: String, isWorkday: Bool = false) {
        self.date = date
        self.name = name
        self.isWorkday = isWorkday
        self.createdAt = Date()
    }
    
    // 更新节假日信息
    func update(name: String? = nil, isWorkday: Bool? = nil) {
        if let name = name {
            self.name = name
        }
        if let isWorkday = isWorkday {
            self.isWorkday = isWorkday
        }
    }
    
    // 判断指定日期是否为节假日
    static func isHoliday(_ date: Date, holidays: [HolidayConfig]) -> Bool {
        let calendar = Calendar.current
        return holidays.contains { holiday in
            calendar.isDate(holiday.date, inSameDayAs: date) && !holiday.isWorkday
        }
    }
    
    // 判断指定日期是否为调休工作日
    static func isWorkday(_ date: Date, holidays: [HolidayConfig]) -> Bool {
        let calendar = Calendar.current
        return holidays.contains { holiday in
            calendar.isDate(holiday.date, inSameDayAs: date) && holiday.isWorkday
        }
    }
}

// 节假日数据管理
extension HolidayConfig {
    // 获取指定年份的法定节假日
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
} 