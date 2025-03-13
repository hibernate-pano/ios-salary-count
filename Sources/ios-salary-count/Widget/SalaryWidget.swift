import SwiftUI
import WidgetKit
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SalaryEntry {
        SalaryEntry(date: Date(), config: SalaryConfig(monthlySalary: 3000), holidays: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryEntry) -> ()) {
        let entry = SalaryEntry(date: Date(), config: SalaryConfig(monthlySalary: 3000), holidays: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 获取配置
        let modelContainer = try? ModelContainer(for: SalaryConfig.self)
        let config = try? modelContainer?.mainContext.fetch(FetchDescriptor<SalaryConfig>()).first
        
        // 获取节假日数据
        Task {
            let holidays = (try? await HolidayHelper.fetchHolidays(year: Calendar.current.component(.year, from: Date()))) ?? []
            
            // 创建时间线
            let currentDate = Date()
            let entry = SalaryEntry(date: currentDate, config: config ?? SalaryConfig(monthlySalary: 3000), holidays: holidays)
            
            // 每分钟更新一次
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate) ?? currentDate
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}

struct SalaryEntry: TimelineEntry {
    let date: Date
    let config: SalaryConfig
    let holidays: [HolidayConfig]
}

struct SalaryWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(config: entry.config, holidays: entry.holidays)
        case .systemMedium:
            MediumWidgetView(config: entry.config, holidays: entry.holidays)
        case .systemLarge:
            LargeWidgetView(config: entry.config, holidays: entry.holidays)
        default:
            SmallWidgetView(config: entry.config, holidays: entry.holidays)
        }
    }
}

struct SalaryWidget: Widget {
    let kind: String = "SalaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SalaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("工资计算")
        .description("实时显示你的工作收入")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    SalaryWidget()
} placeholder: {
    SalaryWidget()
} 