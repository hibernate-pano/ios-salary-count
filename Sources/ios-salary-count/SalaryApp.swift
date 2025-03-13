import SwiftUI
import SwiftData

@main
struct SalaryApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    // 初始化应用
                    await appState.initialize()
                }
        }
    }
}

class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var salaryConfig: SalaryConfig?
    @Published var holidayConfigs: [HolidayConfig] = []
    @Published var showOnboarding = false
    
    private let dataManager = DataManager.shared
    private let userDefaults = UserDefaults.standard
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    init() {
        // 检查是否需要显示引导页
        showOnboarding = !userDefaults.bool(forKey: hasSeenOnboardingKey)
    }
    
    // 初始化应用
    func initialize() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. 加载工资配置
            let configs = try dataManager.fetchSalaryConfigs()
            salaryConfig = configs.first ?? SalaryConfig()
            
            // 2. 同步节假日数据
            try await HolidayConfig.syncCurrentYearHolidays()
            
            // 3. 加载节假日配置
            holidayConfigs = try dataManager.fetchHolidayConfigs()
        } catch {
            self.error = error
        }
    }
    
    // 更新工资配置
    func updateSalaryConfig(_ config: SalaryConfig) {
        do {
            if let existingConfig = salaryConfig {
                try dataManager.updateSalaryConfig(existingConfig)
            } else {
                try dataManager.addSalaryConfig(config)
            }
            salaryConfig = config
        } catch {
            self.error = error
        }
    }
    
    // 同步节假日数据
    func syncHolidays() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await HolidayConfig.syncCurrentYearHolidays()
            holidayConfigs = try dataManager.fetchHolidayConfigs()
        } catch {
            self.error = error
        }
    }
    
    // 导出数据
    func exportData() throws -> Data {
        return try dataManager.exportData()
    }
    
    // 导入数据
    func importData(_ data: Data) throws {
        try dataManager.importData(data)
        
        // 重新加载数据
        let configs = try dataManager.fetchSalaryConfigs()
        salaryConfig = configs.first
        
        holidayConfigs = try dataManager.fetchHolidayConfigs()
    }
    
    // 清除错误
    func clearError() {
        error = nil
    }
    
    // 完成引导
    func completeOnboarding() {
        userDefaults.set(true, forKey: hasSeenOnboardingKey)
        showOnboarding = false
    }
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView(isPresented: $appState.showOnboarding)
                    .onDisappear {
                        appState.completeOnboarding()
                    }
            } else {
                TabView {
                    ConfigView()
                        .tabItem {
                            Label("设置", systemImage: "gear")
                        }
                    
                    Text("统计")
                        .tabItem {
                            Label("统计", systemImage: "chart.bar")
                        }
                }
                .overlay {
                    if appState.isLoading {
                        LoadingOverlay(message: "加载中...")
                    }
                }
                .errorAlert(error: appState.error) {
                    appState.clearError()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 