import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let config: SalaryConfig
    let holidays: [HolidayConfig]
    
    private var calculator: SalaryCalculator {
        SalaryCalculator(config: config, holidays: holidays)
    }
    
    private var workStatus: WorkStatus {
        WorkDayHelper.getWorkStatus(for: Date(), workDays: config.workDays, holidays: holidays)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部：工作状态和每秒收入
            HStack {
                Image(systemName: workStatus.icon)
                Text(workStatus.description)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.2f元/秒", config.salaryPerSecond))
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            // 中间：收入统计
            HStack(spacing: 16) {
                // 今日收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f元", calculator.calculateTodayEarnings()))
                        .font(.title2)
                        .bold()
                }
                
                Divider()
                
                // 本月收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月累计")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f元", calculator.calculateMonthEarnings()))
                        .font(.title2)
                        .bold()
                }
                
                Divider()
                
                // 年度收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("年度累计")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f元", calculator.calculateYearEarnings()))
                        .font(.title2)
                        .bold()
                }
            }
            
            // 底部：月薪和工作时间信息
            HStack {
                Text(String(format: "月薪：%.2f元", config.monthlySalary))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "工作时间：%02d:%02d-%02d:%02d",
                          Calendar.current.component(.hour, from: config.workStartTime),
                          Calendar.current.component(.minute, from: config.workStartTime),
                          Calendar.current.component(.hour, from: config.workEndTime),
                          Calendar.current.component(.minute, from: config.workEndTime)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    LargeWidgetView(
        config: SalaryConfig(),
        holidays: []
    )
    .previewContext(WidgetPreviewContext(family: .systemLarge))
} 