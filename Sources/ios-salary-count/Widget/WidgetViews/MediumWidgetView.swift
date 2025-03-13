import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let config: SalaryConfig
    let holidays: [HolidayConfig]
    
    private var calculator: SalaryCalculator {
        SalaryCalculator(config: config, holidays: holidays)
    }
    
    private var workStatus: WorkStatus {
        WorkDayHelper.getWorkStatus(for: Date(), workDays: config.workDays, holidays: holidays)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：今日收入
            VStack(alignment: .leading, spacing: 8) {
                // 工作状态
                HStack {
                    Image(systemName: workStatus.icon)
                    Text(workStatus.description)
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f元/秒", config.salaryPerSecond))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                // 今日收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f元", calculator.calculateTodayEarnings()))
                        .font(.title2)
                        .bold()
                }
            }
            
            Divider()
            
            // 右侧：本月收入
            VStack(alignment: .leading, spacing: 8) {
                Text("本月累计")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f元", calculator.calculateMonthEarnings()))
                    .font(.title2)
                    .bold()
            }
        }
        .padding()
    }
}

#Preview {
    MediumWidgetView(
        config: SalaryConfig(),
        holidays: []
    )
    .previewContext(WidgetPreviewContext(family: .systemMedium))
} 