import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var colorScheme: ColorScheme = .light
    
    private init() {
        // 从 UserDefaults 读取主题设置
        if let isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            colorScheme = isDarkMode ? .dark : .light
        } else {
            // 默认跟随系统
            colorScheme = .light
        }
    }
    
    // 主题颜色
    var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var accentColor: Color {
        colorScheme == .dark ? .blue : .blue
    }
    
    var dividerColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    // 切换主题
    func toggleTheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
        UserDefaults.standard.set(colorScheme == .dark, forKey: "isDarkMode")
    }
    
    // 跟随系统主题
    func followSystemTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            colorScheme = windowScene.windows.first?.overrideUserInterfaceStyle == .dark ? .dark : .light
        }
    }
} 