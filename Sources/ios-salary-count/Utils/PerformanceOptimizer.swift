import Foundation

class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    // 缓存键
    private enum CacheKey {
        static let workDaysInMonth = "workDaysInMonth"
        static let workDaysInYear = "workDaysInYear"
        static let dailyWorkSeconds = "dailyWorkSeconds"
        static let salaryPerSecond = "salaryPerSecond"
    }
    
    // 缓存过期时间（秒）
    private let cacheExpiration: TimeInterval = 3600 // 1小时
    
    private var cache: [String: CacheItem] = [:]
    private let calendar = Calendar.current
    
    private init() {}
    
    // MARK: - 缓存管理
    
    private struct CacheItem {
        let value: Any
        let timestamp: Date
        
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < PerformanceOptimizer.shared.cacheExpiration
        }
    }
    
    private func setCache<T>(_ value: T, for key: String) {
        cache[key] = CacheItem(value: value, timestamp: Date())
    }
    
    private func getCache<T>(for key: String) -> T? {
        guard let item = cache[key], item.isValid else {
            cache.removeValue(forKey: key)
            return nil
        }
        return item.value as? T
    }
    
    private func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - 性能优化方法
    
    // 计算当月工作日数（带缓存）
    func workDaysInMonth(year: Int, month: Int, workDays: Set<Int>) -> Int {
        let key = "\(CacheKey.workDaysInMonth)_\(year)_\(month)"
        
        if let cached: Int = getCache(for: key) {
            return cached
        }
        
        let result = calendar.daysInMonth(year: year, month: month, workDays: workDays)
        setCache(result, for: key)
        return result
    }
    
    // 计算年度工作日数（带缓存）
    func workDaysInYear(year: Int, workDays: Set<Int>) -> Int {
        let key = "\(CacheKey.workDaysInYear)_\(year)"
        
        if let cached: Int = getCache(for: key) {
            return cached
        }
        
        var total = 0
        for month in 1...12 {
            total += workDaysInMonth(year: year, month: month, workDays: workDays)
        }
        
        setCache(total, for: key)
        return total
    }
    
    // 计算每日工作秒数（带缓存）
    func dailyWorkSeconds(workStartTime: Date, workEndTime: Date, lunchStartTime: Date?, lunchEndTime: Date?) -> TimeInterval {
        let key = "\(CacheKey.dailyWorkSeconds)_\(workStartTime.timeIntervalSince1970)_\(workEndTime.timeIntervalSince1970)"
        
        if let cached: TimeInterval = getCache(for: key) {
            return cached
        }
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: workStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: workEndTime)
        
        var totalSeconds: TimeInterval = 0
        
        if let startHour = startComponents.hour,
           let startMinute = startComponents.minute,
           let endHour = endComponents.hour,
           let endMinute = endComponents.minute {
            
            let startSeconds = TimeInterval(startHour * 3600 + startMinute * 60)
            let endSeconds = TimeInterval(endHour * 3600 + endMinute * 60)
            totalSeconds = endSeconds - startSeconds
            
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
        
        setCache(totalSeconds, for: key)
        return totalSeconds
    }
    
    // 计算每秒工资（带缓存）
    func salaryPerSecond(monthlySalary: Double, workDaysInMonth: Int, dailyWorkSeconds: TimeInterval) -> Double {
        let key = "\(CacheKey.salaryPerSecond)_\(monthlySalary)_\(workDaysInMonth)_\(dailyWorkSeconds)"
        
        if let cached: Double = getCache(for: key) {
            return cached
        }
        
        let dailySalary = monthlySalary / Double(workDaysInMonth)
        let result = dailySalary / dailyWorkSeconds
        
        setCache(result, for: key)
        return result
    }
    
    // MARK: - 性能监控
    
    private var performanceMetrics: [String: [TimeInterval]] = [:]
    
    func startPerformanceTracking(for operation: String) {
        performanceMetrics[operation] = []
    }
    
    func trackPerformance(for operation: String, duration: TimeInterval) {
        if performanceMetrics[operation] == nil {
            performanceMetrics[operation] = []
        }
        performanceMetrics[operation]?.append(duration)
        
        // 只保留最近100次的数据
        if performanceMetrics[operation]?.count ?? 0 > 100 {
            performanceMetrics[operation]?.removeFirst()
        }
    }
    
    func getAveragePerformance(for operation: String) -> TimeInterval? {
        guard let metrics = performanceMetrics[operation], !metrics.isEmpty else {
            return nil
        }
        return metrics.reduce(0, +) / Double(metrics.count)
    }
    
    // MARK: - 内存管理
    
    func clearAllCache() {
        clearCache()
        performanceMetrics.removeAll()
    }
}

// Calendar 扩展
extension Calendar {
    func daysInMonth(year: Int, month: Int, workDays: Set<Int>) -> Int {
        let range = self.range(of: .day, in: .month, for: self.date(from: DateComponents(year: year, month: month, day: 1))!)!
        let daysInMonth = range.count
        
        var workDaysCount = 0
        for day in 1...daysInMonth {
            if let date = self.date(from: DateComponents(year: year, month: month, day: day)) {
                let weekday = self.component(.weekday, from: date)
                if workDays.contains(weekday) {
                    workDaysCount += 1
                }
            }
        }
        
        return workDaysCount
    }
} 