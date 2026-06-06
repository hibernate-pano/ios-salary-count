import Foundation

/// App 与 Widget 共享存储的约定。
///
/// App 主进程和 Widget extension 是两个独立进程，只能通过
/// App Group 共享的 UserDefaults 交换配置。两个 target 都必须
/// 在 entitlements 里声明同一个 App Group ID。
enum AppGroup {
    /// App Group 标识符。需在 App 和 Widget 两个 target 的
    /// entitlements 中保持一致。真机部署时还需在开发者账号开启该能力。
    static let identifier = "group.com.jasper.salarycount"

    /// 共享的 UserDefaults。
    /// 有 App Group entitlement 时用共享 suite；否则回退到 standard，
    /// 保证免费账号真机测试时 App 自身仍能持久化（仅小组件读不到）。
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// 配置存储的键。
    static let configKey = "salary_config"

    /// 配色主题存储的键（小组件读取以跟随 App 主题）。
    static let accentThemeKey = "accent_theme"
}

extension SalaryConfig {
    /// 从共享存储读取配置。读不到（未配置/解码失败/App Group 不可用）返回 nil。
    static func loadSharedIfPresent(from defaults: UserDefaults? = AppGroup.defaults) -> SalaryConfig? {
        guard let defaults,
              let data = defaults.data(forKey: AppGroup.configKey),
              let config = try? JSONDecoder().decode(SalaryConfig.self, from: data) else {
            return nil
        }
        return config
    }

    /// 从共享存储读取配置，没有则返回默认配置（App 内使用，默认值无害）。
    static func loadShared(from defaults: UserDefaults? = AppGroup.defaults) -> SalaryConfig {
        loadSharedIfPresent(from: defaults) ?? SalaryConfig()
    }

    /// 写入共享存储。App Group 不可用时静默失败（不崩溃）。
    func saveShared(to defaults: UserDefaults? = AppGroup.defaults) {
        guard let defaults, let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: AppGroup.configKey)
    }
}
