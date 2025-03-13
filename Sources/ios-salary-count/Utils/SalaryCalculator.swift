import Foundation

class SalaryCalculator {
    private let config: SalaryConfig
    private let holidays: [HolidayConfig]
    private let optimizer = PerformanceOptimizer.shared
    
    init(config: SalaryConfig, holidays: [HolidayConfig] = []) {
        self.config = config
        self.holidays = holidays
    }
    
    // 计算今日收入
    func calculateTodayEarnings() -> Double {
        let startTime = Date()
        let now = Date()
        
        // 检查今天是否是工作日
        if !isWorkday(now) {
            // 如果是节假日，计算节假日加班工资
            return calculateHolidayOvertimeEarnings(for: now)
        }
        
        // 计算正常工作时间的收入
        let normalWorkTime = calculateTodayWorkTime()
        let normalEarnings = normalWorkTime * config.salaryPerSecond
        
        // 计算加班时间的收入
        let overtimeSeconds = config.calculateOvertimeSeconds(for: now)
        let overtimeEarnings = overtimeSeconds * config.salaryPerSecond * config.overtimeRate
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "calculateTodayEarnings", duration: duration)
        
        return normalEarnings + overtimeEarnings
    }
    
    // 计算本月收入
    func calculateMonthEarnings() -> Double {
        let startTime = Date()
        let now = Date()
        let calendar = Calendar.current
        
        // 获取本月的工作日数
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let workDaysInMonth = optimizer.workDaysInMonth(year: year, month: month, workDays: config.workDays)
        
        // 计算本月已工作天数
        var workedDays = 0
        let today = calendar.component(.day, from: now)
        
        for day in 1...today {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                if isWorkday(date) {
                    workedDays += 1
                }
            }
        }
        
        // 计算本月收入
        let dailySalary = config.monthlySalary / Double(workDaysInMonth)
        let monthEarnings = dailySalary * Double(workedDays)
        
        // 加上今天的收入
        let result = monthEarnings + calculateTodayEarnings()
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "calculateMonthEarnings", duration: duration)
        
        return result
    }
    
    // 计算年度收入
    func calculateYearEarnings() -> Double {
        let startTime = Date()
        let now = Date()
        let calendar = Calendar.current
        
        // 获取今年的工作日数
        let year = calendar.component(.year, from: now)
        let workDaysInYear = optimizer.workDaysInYear(year: year, workDays: config.workDays)
        
        // 计算年度收入
        let dailySalary = config.monthlySalary * 12 / Double(workDaysInYear)
        let yearEarnings = dailySalary * Double(workDaysInYear)
        
        // 减去未工作月份的收入
        let currentMonth = calendar.component(.month, from: now)
        let remainingMonths = 12 - currentMonth
        let remainingEarnings = config.monthlySalary * Double(remainingMonths)
        
        let result = yearEarnings - remainingEarnings + calculateMonthEarnings()
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "calculateYearEarnings", duration: duration)
        
        return result
    }
    
    // 计算今日工作时间（秒）
    private func calculateTodayWorkTime() -> TimeInterval {
        let startTime = Date()
        let now = Date()
        let calendar = Calendar.current
        
        // 获取今天的开始和结束时间
        let today = calendar.startOfDay(for: now)
        let workStart = calendar.date(bySettingHour: calendar.component(.hour, from: config.workStartTime),
                                    minute: calendar.component(.minute, from: config.workStartTime),
                                    second: 0,
                                    of: today)!
        let workEnd = calendar.date(bySettingHour: calendar.component(.hour, from: config.workEndTime),
                                  minute: calendar.component(.minute, from: config.workEndTime),
                                  second: 0,
                                  of: today)!
        
        // 如果现在在工作时间之前，返回0
        if now < workStart {
            return 0
        }
        
        // 如果现在在工作时间之后，返回总工作时间
        if now > workEnd {
            return config.dailyWorkSeconds
        }
        
        // 计算已工作时间
        var workTime = now.timeIntervalSince(workStart)
        
        // 如果有午休时间，需要减去午休时间
        if let lunchStart = config.lunchStartTime,
           let lunchEnd = config.lunchEndTime {
            let lunchStartToday = calendar.date(bySettingHour: calendar.component(.hour, from: lunchStart),
                                              minute: calendar.component(.minute, from: lunchStart),
                                              second: 0,
                                              of: today)!
            let lunchEndToday = calendar.date(bySettingHour: calendar.component(.hour, from: lunchEnd),
                                            minute: calendar.component(.minute, from: lunchEnd),
                                            second: 0,
                                            of: today)!
            
            // 如果现在在午休时间，返回午休前的工作时间
            if now >= lunchStartToday && now <= lunchEndToday {
                workTime = lunchStartToday.timeIntervalSince(workStart)
            }
            // 如果现在在午休后，需要减去午休时间
            else if now > lunchEndToday {
                workTime -= lunchEndToday.timeIntervalSince(lunchStartToday)
            }
        }
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "calculateTodayWorkTime", duration: duration)
        
        return workTime
    }
    
    // 判断指定日期是否为工作日
    private func isWorkday(_ date: Date) -> Bool {
        let startTime = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 检查是否是配置的工作日
        if config.workDays.contains(weekday) {
            // 检查是否是节假日
            if HolidayConfig.isHoliday(date, holidays: holidays) {
                return false
            }
            return true
        }
        
        // 检查是否是调休工作日
        let result = HolidayConfig.isWorkday(date, holidays: holidays)
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "isWorkday", duration: duration)
        
        return result
    }
    
    // 计算节假日加班收入
    private func calculateHolidayOvertimeEarnings(for date: Date) -> Double {
        let overtimeSeconds = config.calculateHolidayOvertimeSeconds(for: date)
        return overtimeSeconds * config.salaryPerSecond * config.holidayOvertimeRate
    }
    
    // 计算跨月工资
    func calculateCrossMonthEarnings(from startDate: Date, to endDate: Date) -> Double {
        let startTime = Date()
        let calendar = Calendar.current
        var totalEarnings: Double = 0
        
        // 获取日期范围内的所有日期
        var currentDate = startDate
        while currentDate <= endDate {
            if isWorkday(currentDate) {
                // 计算正常工作时间的收入
                let normalWorkTime = calculateWorkTime(for: currentDate)
                let normalEarnings = normalWorkTime * config.salaryPerSecond
                
                // 计算加班时间的收入
                let overtimeSeconds = config.calculateOvertimeSeconds(for: currentDate)
                let overtimeEarnings = overtimeSeconds * config.salaryPerSecond * config.overtimeRate
                
                totalEarnings += normalEarnings + overtimeEarnings
            } else {
                // 计算节假日加班收入
                totalEarnings += calculateHolidayOvertimeEarnings(for: currentDate)
            }
            
            // 移动到下一天
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "calculateCrossMonthEarnings", duration: duration)
        
        return totalEarnings
    }
    
    // 计算指定日期的工作时间（秒）
    private func calculateWorkTime(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        // 获取工作开始和结束时间
        let workStart = calendar.date(bySettingHour: calendar.component(.hour, from: config.workStartTime),
                                    minute: calendar.component(.minute, from: config.workStartTime),
                                    second: 0,
                                    of: today)!
        let workEnd = calendar.date(bySettingHour: calendar.component(.hour, from: config.workEndTime),
                                  minute: calendar.component(.minute, from: config.workEndTime),
                                  second: 0,
                                  of: today)!
        
        // 如果是过去的工作日，返回全天工作时间
        if date < Date() {
            return config.dailyWorkSeconds
        }
        
        // 如果是今天，返回已工作时间
        if calendar.isDateInToday(date) {
            return calculateTodayWorkTime()
        }
        
        // 如果是未来的工作日，返回0
        return 0
    }
} 