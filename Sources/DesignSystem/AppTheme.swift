import SwiftUI

/// 配色主题（与明暗模式独立）。
enum AccentTheme: String, CaseIterable, Identifiable {
    case green, gold, pink, blue

    var id: String { rawValue }

    /// 设置页显示名。
    var displayName: String {
        switch self {
        case .green: return "薄荷绿"
        case .gold: return "鎏金"
        case .pink: return "樱粉"
        case .blue: return "海蓝"
        }
    }

    /// 写入 App Group 共享存储（供小组件读取以跟随主题）。
    func saveShared(to defaults: UserDefaults? = AppGroup.defaults) {
        defaults?.set(rawValue, forKey: AppGroup.accentThemeKey)
    }

    /// 从 App Group 读取；无数据回退绿色。
    static func loadShared(from defaults: UserDefaults? = AppGroup.defaults) -> AccentTheme {
        guard let raw = defaults?.string(forKey: AppGroup.accentThemeKey),
              let theme = AccentTheme(rawValue: raw) else { return .green }
        return theme
    }

    /// 主色。
    var primary: Color {
        switch self {
        case .green: return Color(red: 0.10, green: 0.78, blue: 0.52)
        case .gold: return Color(red: 0.95, green: 0.70, blue: 0.22)
        case .pink: return Color(red: 0.96, green: 0.42, blue: 0.62)
        case .blue: return Color(red: 0.18, green: 0.56, blue: 0.96)
        }
    }

    /// 次色（与主色构成渐变的另一端）。
    var secondary: Color {
        switch self {
        case .green: return Color(red: 0.05, green: 0.62, blue: 0.66)
        case .gold: return Color(red: 0.93, green: 0.50, blue: 0.16)
        case .pink: return Color(red: 0.78, green: 0.30, blue: 0.74)
        case .blue: return Color(red: 0.10, green: 0.38, blue: 0.82)
        }
    }
}

/// 明暗模式（与配色独立）。
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    /// 映射到 SwiftUI 的 preferredColorScheme（system → nil）。
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// 由 AccentTheme 解析出的一组可用色与渐变，供视图直接取用。
struct BrandTheme {
    let accent: AccentTheme

    var primary: Color { accent.primary }
    var secondary: Color { accent.secondary }

    /// 主渐变（hero 卡片，左上→右下）。
    var heroGradient: LinearGradient {
        LinearGradient(colors: [primary, secondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// 休息日渐变：暖橙，区别于工作日（所有配色共用，表达「休息」语义）。
    var restGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 1.0, green: 0.62, blue: 0.30),
                                Color(red: 0.96, green: 0.44, blue: 0.32)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// 进度条渐变。
    var progressGradient: LinearGradient {
        LinearGradient(colors: [primary.opacity(0.7), primary],
                       startPoint: .leading, endPoint: .trailing)
    }

    /// 根据「是否工作日」选择 hero 渐变。
    func heroGradient(isWorkday: Bool) -> LinearGradient {
        isWorkday ? heroGradient : restGradient
    }

    static let green = BrandTheme(accent: .green)
}

// MARK: - 环境注入

private struct BrandThemeKey: EnvironmentKey {
    static let defaultValue = BrandTheme.green
}

extension EnvironmentValues {
    /// 当前配色主题。视图用 `@Environment(\.brand)` 读取。
    var brand: BrandTheme {
        get { self[BrandThemeKey.self] }
        set { self[BrandThemeKey.self] = newValue }
    }
}
