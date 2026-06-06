import Foundation
import Combine
import SwiftUI
import WidgetKit

/// 应用状态中枢：持有配置、驱动每秒刷新、负责持久化到 App Group。
@MainActor
final class SalaryStore: ObservableObject {
    /// 用户配置。任何修改都会自动持久化并刷新 Widget。
    @Published var config: SalaryConfig {
        didSet { save() }
    }

    /// 每秒更新的当前时刻，驱动 App 内 UI 实时跳动。
    @Published private(set) var now: Date = Date()

    private var timer: AnyCancellable?
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = AppGroup.defaults) {
        self.defaults = defaults
        self.config = SalaryConfig.loadShared(from: defaults)
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

    /// 写入共享存储，并通知 Widget 重新加载时间线。
    private func save() {
        config.saveShared(to: defaults)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
