import SwiftUI
import Combine
import WidgetKit

/// 外观设置中枢：配色主题 + 明暗模式，持久化到 UserDefaults。
@MainActor
final class ThemeStore: ObservableObject {
    @AppStorage("accentTheme") private var accentRaw = AccentTheme.green.rawValue
    @AppStorage("appearanceMode") private var appearanceRaw = AppearanceMode.system.rawValue

    init() {
        // 启动时把当前主题同步到 App Group，保证小组件与 App 一致。
        AccentTheme(rawValue: accentRaw)?.saveShared()
    }

    /// 当前配色主题。
    var accent: AccentTheme {
        get { AccentTheme(rawValue: accentRaw) ?? .green }
        set {
            objectWillChange.send()
            accentRaw = newValue.rawValue
            // 写入共享存储并刷新小组件，使其跟随 App 主题。
            newValue.saveShared()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 当前明暗模式。
    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { objectWillChange.send(); appearanceRaw = newValue.rawValue }
    }

    /// 供视图取色的主题包。
    var brand: BrandTheme { BrandTheme(accent: accent) }

    /// 供根视图设置的 preferredColorScheme。
    var colorScheme: ColorScheme? { appearance.colorScheme }
}
