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
        workDays: Set<Int> = [1, 2, 3, 4, 5] // 默认周一到周五
    ) {
        self.monthlySalary = monthlySalary
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lunchStartTime = lunchStartTime
        self.lunchEndTime = lunchEndTime
        self.workDays = workDays
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
        workDays: Set<Int>? = nil
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