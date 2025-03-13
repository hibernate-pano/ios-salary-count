import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                TabView {
                    SalaryView()
                        .tabItem {
                            Label("工资", systemImage: "dollarsign.circle.fill")
                        }
                    
                    ConfigView()
                        .tabItem {
                            Label("设置", systemImage: "gear")
                        }
                }
                .accentColor(themeManager.accentColor)
            }
        }
        .background(themeManager.backgroundColor)
        .foregroundColor(themeManager.textColor)
        .overlay {
            if appState.isLoading {
                LoadingOverlay()
            }
        }
        .alert("错误", isPresented: $appState.showError) {
            Button("确定") {
                appState.clearError()
            }
        } message: {
            Text(appState.error ?? "未知错误")
        }
    }
}

struct SalaryView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedCard: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日收入卡片
                    EarningsCard(
                        title: "今日收入",
                        amount: appState.calculateTodayEarnings(),
                        colorScheme: themeManager.colorScheme,
                        isSelected: selectedCard == "today",
                        onTap: { selectedCard = "today" }
                    )
                    
                    // 本月收入卡片
                    EarningsCard(
                        title: "本月收入",
                        amount: appState.calculateMonthEarnings(),
                        colorScheme: themeManager.colorScheme,
                        isSelected: selectedCard == "month",
                        onTap: { selectedCard = "month" }
                    )
                    
                    // 年度收入卡片
                    EarningsCard(
                        title: "年度收入",
                        amount: appState.calculateYearEarnings(),
                        colorScheme: themeManager.colorScheme,
                        isSelected: selectedCard == "year",
                        onTap: { selectedCard = "year" }
                    )
                }
                .padding()
            }
            .navigationTitle("工资计算器")
            .background(themeManager.backgroundColor)
        }
    }
}

struct EarningsCard: View {
    let title: String
    let amount: Double
    let colorScheme: ColorScheme
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Text(String(format: "%.2f", amount))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1),
                   radius: isSelected ? 10 : 5,
                   x: 0,
                   y: isSelected ? 5 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct LoadingOverlay: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("加载中...")
                    .foregroundColor(.white)
                    .padding(.top)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
} 