import WidgetKit
import SwiftUI

struct SalaryWidgetEntryView: View {
    var entry: SalaryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.isConfigured {
            UnconfiguredView()
        } else {
            switch family {
            case .systemSmall:
                SmallSalaryView(entry: entry)
            case .systemMedium:
                MediumSalaryView(entry: entry)
            case .systemLarge:
                LargeSalaryView(entry: entry)
            default:
                SmallSalaryView(entry: entry)
            }
        }
    }
}

struct SalaryWidget: Widget {
    let kind = "SalaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalaryProvider()) { entry in
            SalaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("工资计算器")
        .description("实时显示你今天的工作收入与进度")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct SalaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalaryWidget()
    }
}
