import Foundation

class WorkDayHelper {
    // 获取指定日期的工作状态
    static func getWorkStatus(for date: Date, workDays: Set<Int>, holidays: [HolidayConfig]) -> WorkStatus {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 检查是否是调休工作日
        if HolidayConfig.isWorkday(date, holidays: holidays) {
            return .workday
        }
        
        // 检查是否是节假日
        if HolidayConfig.isHoliday(date, holidays: holidays) {
            return .holiday
        }
        
        // 检查是否是常规工作日
        if workDays.contains(weekday) {
            return .workday
        }
        
        return .weekend
    }
    
    // 获取下一个工作日
    static func getNextWorkday(from date: Date, workDays: Set<Int>, holidays: [HolidayConfig]) -> Date {
        var nextDate = date
        let calendar = Calendar.current
        
        repeat {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        } while !isWorkday(nextDate, workDays: workDays, holidays: holidays)
        
        return nextDate
    }
    
    // 获取上一个工作日
    static func getPreviousWorkday(from date: Date, workDays: Set<Int>, holidays: [HolidayConfig]) -> Date {
        var previousDate = date
        let calendar = Calendar.current
        
        repeat {
            previousDate = calendar.date(byAdding: .day, value: -1, to: previousDate) ?? previousDate
        } while !isWorkday(previousDate, workDays: workDays, holidays: holidays)
        
        return previousDate
    }
    
    // 判断指定日期是否为工作日
    static func isWorkday(_ date: Date, workDays: Set<Int>, holidays: [HolidayConfig]) -> Bool {
        return getWorkStatus(for: date, workDays: workDays, holidays: holidays) == .workday
    }
    
    // 获取指定日期的工作状态描述
    static func getWorkStatusDescription(for date: Date, workDays: Set<Int>, holidays: [HolidayConfig]) -> String {
        let status = getWorkStatus(for: date, workDays: workDays, holidays: holidays)
        
        switch status {
        case .workday:
            if HolidayConfig.isWorkday(date, holidays: holidays) {
                return "调休工作日"
            }
            return "工作日"
        case .holiday:
            if let holiday = holidays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                return holiday.name
            }
            return "节假日"
        case .weekend:
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekday == 1 ? "周日" : "周六"
        }
    }
}

// 工作状态枚举
enum WorkStatus {
    case workday
    case holiday
    case weekend
} 