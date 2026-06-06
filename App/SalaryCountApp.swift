import SwiftUI

@main
struct SalaryCountApp: App {
    @StateObject private var store = SalaryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
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
