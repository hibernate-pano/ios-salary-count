import SwiftUI
import SwiftData

struct ConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [SalaryConfig]
    
    @State private var monthlySalary: Double = 3000
    @State private var workStartTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var workEndTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var lunchStartTime: Date? = Calendar.current.date(from: DateComponents(hour: 12, minute: 0))
    @State private var lunchEndTime: Date? = Calendar.current.date(from: DateComponents(hour: 13, minute: 0))
    @State private var workDays: Set<Int> = [1, 2, 3, 4, 5]
    
    private let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("工资设置") {
                    HStack {
                        Text("月薪")
                        Spacer()
                        TextField("月薪", value: $monthlySalary, format: .currency(code: "CNY"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("工作时间") {
                    DatePicker("上班时间", selection: $workStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("下班时间", selection: $workEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section("午休时间") {
                    Toggle("启用午休", isOn: Binding(
                        get: { lunchStartTime != nil && lunchEndTime != nil },
                        set: { enabled in
                            if enabled {
                                lunchStartTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0))
                                lunchEndTime = Calendar.current.date(from: DateComponents(hour: 13, minute: 0))
                            } else {
                                lunchStartTime = nil
                                lunchEndTime = nil
                            }
                        }
                    ))
                    
                    if lunchStartTime != nil && lunchEndTime != nil {
                        DatePicker("午休开始", selection: Binding(
                            get: { lunchStartTime ?? Date() },
                            set: { lunchStartTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                        
                        DatePicker("午休结束", selection: Binding(
                            get: { lunchEndTime ?? Date() },
                            set: { lunchEndTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("工作日") {
                    ForEach(0..<7) { index in
                        Toggle(weekdays[index], isOn: Binding(
                            get: { workDays.contains(index) },
                            set: { isSelected in
                                if isSelected {
                                    workDays.insert(index)
                                } else {
                                    workDays.remove(index)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("工资设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveConfig()
                    }
                }
            }
            .onAppear {
                loadConfig()
            }
        }
    }
    
    private func loadConfig() {
        if let config = configs.first {
            monthlySalary = config.monthlySalary
            workStartTime = config.workStartTime
            workEndTime = config.workEndTime
            lunchStartTime = config.lunchStartTime
            lunchEndTime = config.lunchEndTime
            workDays = config.workDays
        }
    }
    
    private func saveConfig() {
        if let config = configs.first {
            config.update(
                monthlySalary: monthlySalary,
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchStartTime: lunchStartTime,
                lunchEndTime: lunchEndTime,
                workDays: workDays
            )
        } else {
            let config = SalaryConfig(
                monthlySalary: monthlySalary,
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lunchStartTime: lunchStartTime,
                lunchEndTime: lunchEndTime,
                workDays: workDays
            )
            modelContext.insert(config)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    ConfigView()
        .modelContainer(for: SalaryConfig.self)
} 