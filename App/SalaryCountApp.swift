import SwiftUI

@main
struct SalaryCountApp: App {
    @StateObject private var store = SalaryStore()
    @StateObject private var themeStore = ThemeStore()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        // UI 测试用：传 -resetOnboarding 强制回到首次启动状态。
        if CommandLine.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    RootView()
                        .environmentObject(store)
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            .environment(\.brand, themeStore.brand)
            .preferredColorScheme(themeStore.colorScheme)
            .environmentObject(themeStore)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("收入", systemImage: "yensign.circle.fill")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SalaryStore())
}
