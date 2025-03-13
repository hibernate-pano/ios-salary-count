import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let config: SalaryConfig
    let holidays: [HolidayConfig]
    
    private var calculator: SalaryCalculator {
        SalaryCalculator(config: config, holidays: holidays)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日收入")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f", calculator.calculateTodayEarnings()))
                    .font(.title2)
                    .bold()
            }
            
            Text("元")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text(WorkDayHelper.getWorkStatusDescription(for: Date(), workDays: config.workDays, holidays: holidays))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.2f/秒", config.salaryPerSecond))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    SmallWidgetView(
        config: SalaryConfig(monthlySalary: 3000),
        holidays: []
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
} 