import Foundation
import Combine
import SwiftUI

/// 应用状态中枢：持有配置、驱动每秒刷新、负责持久化。
@MainActor
final class SalaryStore: ObservableObject {
    /// 用户配置。任何修改都会自动持久化。
    @Published var config: SalaryConfig {
        didSet { save() }
    }

    /// 每秒更新的当前时刻，驱动 UI 实时跳动。
    @Published private(set) var now: Date = Date()

    private var timer: AnyCancellable?
    private let defaults: UserDefaults
    private let storageKey = "salary_config"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.config = SalaryStore.load(from: defaults, key: storageKey) ?? SalaryConfig()
        startTimer()
    }

    // MARK: - 计算

    /// 基于当前配置和时刻构造引擎。
    var engine: SalaryEngine {
        SalaryEngine(config: config)
    }

    var todayEarnings: Double { engine.todayEarnings(now: now) }
    var monthEarnings: Double { engine.monthEarnings(now: now) }
    var yearEarnings: Double { engine.yearEarnings(now: now) }
    var isWorkdayToday: Bool { engine.isWorkday(now) }

    // MARK: - 计时器

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    // MARK: - 持久化

    private func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> SalaryConfig? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SalaryConfig.self, from: data)
    }
}
