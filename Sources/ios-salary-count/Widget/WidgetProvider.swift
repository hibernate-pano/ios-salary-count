import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let appState = AppState.shared
    private let optimizer = PerformanceOptimizer.shared
    
    func placeholder(in context: Context) -> SalaryEntry {
        SalaryEntry(date: Date(), todayEarnings: 0, monthEarnings: 0, yearEarnings: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SalaryEntry) -> ()) {
        let startTime = Date()
        
        // 使用缓存的计算结果
        let todayEarnings = appState.calculateTodayEarnings()
        let monthEarnings = appState.calculateMonthEarnings()
        let yearEarnings = appState.calculateYearEarnings()
        
        let entry = SalaryEntry(
            date: Date(),
            todayEarnings: todayEarnings,
            monthEarnings: monthEarnings,
            yearEarnings: yearEarnings
        )
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "getSnapshot", duration: duration)
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryEntry>) -> ()) {
        let startTime = Date()
        let currentDate = Date()
        let calendar = Calendar.current
        
        // 计算下一个更新时间
        var nextUpdateDate: Date
        if let workStart = appState.config.workStartTime {
            let workStartComponents = calendar.dateComponents([.hour, .minute], from: workStart)
            if let nextWorkStart = calendar.date(bySettingHour: workStartComponents.hour ?? 0,
                                               minute: workStartComponents.minute ?? 0,
                                               second: 0,
                                               of: currentDate) {
                nextUpdateDate = nextWorkStart
                if nextUpdateDate <= currentDate {
                    nextUpdateDate = calendar.date(byAddingDay: 1, to: nextUpdateDate) ?? nextUpdateDate
                }
            } else {
                nextUpdateDate = calendar.date(byAddingHour: 1, to: currentDate) ?? currentDate
            }
        } else {
            nextUpdateDate = calendar.date(byAddingHour: 1, to: currentDate) ?? currentDate
        }
        
        // 生成时间线
        var entries: [SalaryEntry] = []
        let entryCount = 24 // 生成24小时的时间线
        
        for hourOffset in 0 ..< entryCount {
            let entryDate = calendar.date(byAddingHour: hourOffset, to: currentDate) ?? currentDate
            
            // 使用缓存的计算结果
            let todayEarnings = appState.calculateTodayEarnings()
            let monthEarnings = appState.calculateMonthEarnings()
            let yearEarnings = appState.calculateYearEarnings()
            
            let entry = SalaryEntry(
                date: entryDate,
                todayEarnings: todayEarnings,
                monthEarnings: monthEarnings,
                yearEarnings: yearEarnings
            )
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        
        // 记录性能
        let duration = Date().timeIntervalSince(startTime)
        optimizer.trackPerformance(for: "getTimeline", duration: duration)
        
        completion(timeline)
    }
}

// 扩展 Calendar 以支持日期计算
extension Calendar {
    func date(byAddingHour hour: Int, to date: Date) -> Date? {
        return self.date(byAdding: .hour, value: hour, to: date)
    }
    
    func date(byAddingDay day: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: day, to: date)
    }
}

struct SalaryEntry: TimelineEntry {
    let date: Date
    let todayEarnings: Double
    let monthEarnings: Double
    let yearEarnings: Double
}

struct SalaryWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SalaryWidget: Widget {
    let kind: String = "SalaryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SalaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("工资计算器")
        .description("实时显示今日、本月和年度收入")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 