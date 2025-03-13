import Foundation
import SwiftData

@Model
final class SalaryConfig {
    // 月薪（元）
    var monthlySalary: Double
    
    // 工作时间配置
    var workStartTime: Date
    var workEndTime: Date
    
    // 午休时间配置（可选）
    var lunchStartTime: Date?
    var lunchEndTime: Date?
    
    // 工作日配置（0-6 代表周日到周六）
    var workDays: Set<Int>
    
    // 加班工资配置
    var overtimeRate: Double // 加班工资倍率（默认1.5）
    var overtimeStartTime: Date? // 加班开始时间（可选）
    var overtimeEndTime: Date? // 加班结束时间（可选）
    
    // 特殊节假日工资倍率
    var holidayOvertimeRate: Double // 节假日加班工资倍率（默认3.0）
    
    // 创建时间
    var createdAt: Date
    
    // 更新时间
    var updatedAt: Date
    
    init(
        monthlySalary: Double = 3000,
        workStartTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        workEndTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date(),
        lunchStartTime: Date? = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)),
        lunchEndTime: Date? = Calendar.current.date(from: DateComponents(hour: 13, minute: 0)),
        workDays: Set<Int> = [1, 2, 3, 4, 5], // 默认周一到周五
        overtimeRate: Double = 1.5,
        overtimeStartTime: Date? = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)),
        overtimeEndTime: Date? = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)),
        holidayOvertimeRate: Double = 3.0
    ) {
        self.monthlySalary = monthlySalary
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchStartTime = lunchStartTime
        self.lunchEndTime = lunchEndTime
        self.workDays = workDays
        self.overtimeRate = overtimeRate
        self.overtimeStartTime = overtimeStartTime
        self.overtimeEndTime = overtimeEndTime
        self.holidayOvertimeRate = holidayOvertimeRate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 更新配置
    func update(
        monthlySalary: Double? = nil,
        workStartTime: Date? = nil,
        workEndTime: Date? = nil,
        lunchStartTime: Date? = nil,
        lunchEndTime: Date? = nil,
        workDays: Set<Int>? = nil,
        overtimeRate: Double? = nil,
        overtimeStartTime: Date? = nil,
        overtimeEndTime: Date? = nil,
        holidayOvertimeRate: Double? = nil
    ) {
        if let monthlySalary = monthlySalary {
            self.monthlySalary = monthlySalary
        }
        if let workStartTime = workStartTime {
            self.workStartTime = workStartTime
        }
        if let workEndTime = workEndTime {
            self.workEndTime = workEndTime
        }
        if let lunchStartTime = lunchStartTime {
            self.lunchStartTime = lunchStartTime
        }
        if let lunchEndTime = lunchEndTime {
            self.lunchEndTime = lunchEndTime
        }
        if let workDays = workDays {
            self.workDays = workDays
        }
        if let overtimeRate = overtimeRate {
            self.overtimeRate = overtimeRate
        }
        if let overtimeStartTime = overtimeStartTime {
            self.overtimeStartTime = overtimeStartTime
        }
        if let overtimeEndTime = overtimeEndTime {
            self.overtimeEndTime = overtimeEndTime
        }
        if let holidayOvertimeRate = holidayOvertimeRate {
            self.holidayOvertimeRate = holidayOvertimeRate
        }
        self.updatedAt = Date()
    }
    
    // 计算每日工作秒数
    var dailyWorkSeconds: TimeInterval {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: workStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: workEndTime)
        
        var totalSeconds: TimeInterval = 0
        
        // 计算工作时间
        if let startHour = startComponents.hour,
           let startMinute = startComponents.minute,
           let endHour = endComponents.hour,
           let endMinute = endComponents.minute {
            
            let startSeconds = TimeInterval(startHour * 3600 + startMinute * 60)
            let endSeconds = TimeInterval(endHour * 3600 + endMinute * 60)
            totalSeconds = endSeconds - startSeconds
            
            // 如果有午休时间，减去午休时间
            if let lunchStart = lunchStartTime,
               let lunchEnd = lunchEndTime {
                let lunchStartComponents = calendar.dateComponents([.hour, .minute], from: lunchStart)
                let lunchEndComponents = calendar.dateComponents([.hour, .minute], from: lunchEnd)
                
                if let lunchStartHour = lunchStartComponents.hour,
                   let lunchStartMinute = lunchStartComponents.minute,
                   let lunchEndHour = lunchEndComponents.hour,
                   let lunchEndMinute = lunchEndComponents.minute {
                    
                    let lunchStartSeconds = TimeInterval(lunchStartHour * 3600 + lunchStartMinute * 60)
                    let lunchEndSeconds = TimeInterval(lunchEndHour * 3600 + lunchEndMinute * 60)
                    totalSeconds -= (lunchEndSeconds - lunchStartSeconds)
                }
            }
        }
        
        return totalSeconds
    }
    
    // 计算每秒工资
    var salaryPerSecond: Double {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let daysInMonth = range.count
        
        // 计算当月工作日数
        let workDaysInMonth = calendar.daysInMonth(workDays: workDays)
        
        // 日工资
        let dailySalary = monthlySalary / Double(workDaysInMonth)
        
        // 每秒工资
        return dailySalary / dailyWorkSeconds
    }
    
    // 计算加班时间（秒）
    func calculateOvertimeSeconds(for date: Date) -> TimeInterval {
        guard let overtimeStart = overtimeStartTime,
              let overtimeEnd = overtimeEndTime else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = date
        
        // 获取今天的加班开始和结束时间
        let today = calendar.startOfDay(for: now)
        let overtimeStartToday = calendar.date(bySettingHour: calendar.component(.hour, from: overtimeStart),
                                             minute: calendar.component(.minute, from: overtimeStart),
                                             second: 0,
                                             of: today)!
        let overtimeEndToday = calendar.date(bySettingHour: calendar.component(.hour, from: overtimeEnd),
                                           minute: calendar.component(.minute, from: overtimeEnd),
                                           second: 0,
                                           of: today)!
        
        // 如果现在在加班时间之前，返回0
        if now < overtimeStartToday {
            return 0
        }
        
        // 如果现在在加班时间之后，返回总加班时间
        if now > overtimeEndToday {
            return overtimeEndToday.timeIntervalSince(overtimeStartToday)
        }
        
        // 计算已加班时间
        return now.timeIntervalSince(overtimeStartToday)
    }
    
    // 计算特殊节假日加班时间（秒）
    func calculateHolidayOvertimeSeconds(for date: Date) -> TimeInterval {
        // 如果是工作日，返回0
        if isWorkday(date) {
            return 0
        }
        
        // 计算全天工作时间
        return dailyWorkSeconds
    }
}

// Calendar 扩展，用于计算工作日
extension Calendar {
    func daysInMonth(workDays: Set<Int>) -> Int {
        let now = Date()
        let range = self.range(of: .day, in: .month, for: now)!
        let daysInMonth = range.count
        
        var workDaysCount = 0
        for day in 1...daysInMonth {
            if let date = self.date(from: DateComponents(year: self.component(.year, from: now),
                                                       month: self.component(.month, from: now),
                                                       day: day)) {
                let weekday = self.component(.weekday, from: date)
                if workDays.contains(weekday) {
                    workDaysCount += 1
                }
            }
        }
        
        return workDaysCount
    }
} 