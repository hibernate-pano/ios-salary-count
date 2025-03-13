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
        return try await HolidayService.shared.fetchHolidays(year: year)
    }
    
    // 同步当前年份的节假日数据
    static func syncCurrentYearHolidays() async throws {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        _ = try await fetchHolidays(year: currentYear)
    }
    
    // 同步指定年份的节假日数据
    static func syncHolidays(year: Int) async throws {
        _ = try await fetchHolidays(year: year)
    }
    
    // 清除指定年份的缓存
    static func clearCache(year: Int) {
        HolidayService.shared.clearCache(year: year)
    }
    
    // 清除所有缓存
    static func clearAllCache() {
        HolidayService.shared.clearAllCache()
    }
} 