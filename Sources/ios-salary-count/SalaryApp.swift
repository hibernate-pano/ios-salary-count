import SwiftUI
import SwiftData

@main
struct SalaryApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: SalaryConfig.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SalaryConfig.self)
} 