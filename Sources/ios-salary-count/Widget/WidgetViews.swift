import SwiftUI

struct SmallWidgetView: View {
    let entry: SalaryEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日收入")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            
            Text(String(format: "%.2f", entry.todayEarnings))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
}

struct MediumWidgetView: View {
    let entry: SalaryEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日收入")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                Text(String(format: "%.2f", entry.todayEarnings))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            Divider()
                .background(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("本月收入")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                Text(String(format: "%.2f", entry.monthEarnings))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            Spacer()
            
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
}

struct LargeWidgetView: View {
    let entry: SalaryEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("工资统计")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
            
            Divider()
                .background(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
            
            VStack(alignment: .leading, spacing: 12) {
                EarningsRow(title: "今日收入", amount: entry.todayEarnings, colorScheme: colorScheme)
                EarningsRow(title: "本月收入", amount: entry.monthEarnings, colorScheme: colorScheme)
                EarningsRow(title: "年度收入", amount: entry.yearEarnings, colorScheme: colorScheme)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
    }
}

struct EarningsRow: View {
    let title: String
    let amount: Double
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            
            Spacer()
            
            Text(String(format: "%.2f", amount))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
}

#Preview("Small Widget") {
    SmallWidgetView(entry: SalaryEntry(
        date: Date(),
        todayEarnings: 123.45,
        monthEarnings: 2345.67,
        yearEarnings: 23456.78
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Medium Widget") {
    MediumWidgetView(entry: SalaryEntry(
        date: Date(),
        todayEarnings: 123.45,
        monthEarnings: 2345.67,
        yearEarnings: 23456.78
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}

#Preview("Large Widget") {
    LargeWidgetView(entry: SalaryEntry(
        date: Date(),
        todayEarnings: 123.45,
        monthEarnings: 2345.67,
        yearEarnings: 23456.78
    ))
    .previewContext(WidgetPreviewContext(family: .systemLarge))
} 