import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [SalaryConfig]
    @EnvironmentObject private var appState: AppState
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @State private var showingSyncAlert = false
    @State private var showingThemePicker = false
    
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
                if let config = configs.first {
                    Section("工资设置") {
                        HStack {
                            Text("月薪")
                            Spacer()
                            TextField("月薪", value: $config.monthlySalary, format: .currency(code: "CNY"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        DatePicker("上班时间", selection: $config.workStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("下班时间", selection: $config.workEndTime, displayedComponents: .hourAndMinute)
                        
                        Toggle("启用午休", isOn: Binding(
                            get: { config.lunchStartTime != nil },
                            set: { enabled in
                                withAnimation {
                                    if enabled {
                                        config.lunchStartTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0))
                                        config.lunchEndTime = Calendar.current.date(from: DateComponents(hour: 13, minute: 0))
                                    } else {
                                        config.lunchStartTime = nil
                                        config.lunchEndTime = nil
                                    }
                                }
                            }
                        ))
                        
                        if config.lunchStartTime != nil {
                            DatePicker("午休开始", selection: Binding(
                                get: { config.lunchStartTime ?? Date() },
                                set: { config.lunchStartTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                            
                            DatePicker("午休结束", selection: Binding(
                                get: { config.lunchEndTime ?? Date() },
                                set: { config.lunchEndTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                        }
                    }
                    
                    Section("工作日设置") {
                        ForEach(1...7, id: \.self) { weekday in
                            let dayName = Calendar.current.weekdaySymbols[weekday - 1]
                            Toggle(dayName, isOn: Binding(
                                get: { config.workDays.contains(weekday) },
                                set: { isSelected in
                                    withAnimation {
                                        if isSelected {
                                            config.workDays.insert(weekday)
                                        } else {
                                            config.workDays.remove(weekday)
                                        }
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section("节假日设置") {
                    Button(action: {
                        Task {
                            await appState.syncHolidays()
                        }
                    }) {
                        HStack {
                            Text("同步节假日")
                            Spacer()
                            if appState.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(appState.isLoading)
                }
                
                Section("主题设置") {
                    Button(action: {
                        showingThemePicker = true
                    }) {
                        HStack {
                            Text("主题")
                            Spacer()
                            Text(themeManager.selectedTheme.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("数据管理") {
                    Button(action: {
                        showingImportPicker = true
                    }) {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        withAnimation {
                            saveConfig()
                        }
                    }
                }
            }
            .onAppear {
                loadConfig()
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        try appState.importData(data)
                    } catch {
                        appState.error = error
                    }
                case .failure(let error):
                    appState.error = error
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(items: [try! appState.exportData()])
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView(themeManager: themeManager)
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

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    themeManager.updateTheme(theme)
                    dismiss()
                }) {
                    HStack {
                        Text(theme.rawValue)
                        Spacer()
                        if themeManager.selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Text(themeManager.getThemeDescription(theme))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("选择主题")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ConfigView()
        .modelContainer(for: SalaryConfig.self)
        .environmentObject(AppState())
} 