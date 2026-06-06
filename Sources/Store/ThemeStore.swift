import SwiftUI
import Combine
import WidgetKit

/// 外观设置中枢：配色主题 + 明暗模式。
///
/// 持久化统一存于 **App Group 共享存储**（与工资配置同域），
/// 这样 App 与小组件读同一份，将来接 iCloud 同步也只需对接一处。
/// 旧版本曾把偏好存在标准域（@AppStorage），首次启动会自动迁移过来，不丢用户选择。
@MainActor
final class ThemeStore: ObservableObject {
    private let defaults: UserDefaults?

    @Published private var accentValue: AccentTheme
    @Published private var appearanceValue: AppearanceMode

    init(defaults: UserDefaults? = AppGroup.defaults) {
        self.defaults = defaults
        ThemeStore.migrateFromStandardIfNeeded(into: defaults)
        accentValue = ThemeStore.loadAccent(defaults)
        appearanceValue = ThemeStore.loadAppearance(defaults)
    }

    /// 当前配色主题。
    var accent: AccentTheme {
        get { accentValue }
        set {
            accentValue = newValue
            defaults?.set(newValue.rawValue, forKey: AppGroup.accentThemeKey)
            WidgetCenter.shared.reloadAllTimelines()   // 小组件跟随主题
        }
    }

    /// 当前明暗模式。
    var appearance: AppearanceMode {
        get { appearanceValue }
        set {
            appearanceValue = newValue
            defaults?.set(newValue.rawValue, forKey: AppGroup.appearanceModeKey)
        }
    }

    /// 供视图取色的主题包。
    var brand: BrandTheme { BrandTheme(accent: accent) }

    /// 供根视图设置的 preferredColorScheme。
    var colorScheme: ColorScheme? { appearance.colorScheme }

    // MARK: - 读取

    private static func loadAccent(_ defaults: UserDefaults?) -> AccentTheme {
        guard let raw = defaults?.string(forKey: AppGroup.accentThemeKey),
              let theme = AccentTheme(rawValue: raw) else { return .green }
        return theme
    }

    private static func loadAppearance(_ defaults: UserDefaults?) -> AppearanceMode {
        guard let raw = defaults?.string(forKey: AppGroup.appearanceModeKey),
              let mode = AppearanceMode(rawValue: raw) else { return .system }
        return mode
    }

    // MARK: - 旧版本迁移

    /// 旧版本把主题/明暗存在标准域的 @AppStorage 键。
    /// 若 App Group 域还没有数据、而标准域有，则迁移过来（一次性，幂等）。
    private static func migrateFromStandardIfNeeded(into defaults: UserDefaults?) {
        guard let defaults else { return }
        let std = UserDefaults.standard

        if defaults.string(forKey: AppGroup.accentThemeKey) == nil,
           let oldAccent = std.string(forKey: "accentTheme") {
            defaults.set(oldAccent, forKey: AppGroup.accentThemeKey)
        }
        if defaults.string(forKey: AppGroup.appearanceModeKey) == nil,
           let oldAppearance = std.string(forKey: "appearanceMode") {
            defaults.set(oldAppearance, forKey: AppGroup.appearanceModeKey)
        }
    }
}
