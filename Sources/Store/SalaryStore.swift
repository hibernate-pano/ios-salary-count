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

    /// Widget 刷新防抖：合并连续配置变更（如拖 DatePicker）为一次重载，
    /// 避免高频触发 reloadAllTimelines 烧光 WidgetKit 刷新预算。
    private var widgetReloadWork: DispatchWorkItem?

    init(defaults: UserDefaults? = AppGroup.defaults) {
        self.defaults = defaults
        self.config = SalaryConfig.loadShared(from: defaults)
        startTimer()
    }

    // MARK: - 计算

    /// 基于当前配置、节假日和时刻构造引擎。
    var engine: SalaryEngine {
        SalaryEngine(config: config, holidays: HolidayData.currentYear(now: now))
    }

    var todayEarnings: Double { engine.todayEarnings(now: now) }
    var monthEarnings: Double { engine.monthEarnings(now: now) }
    var yearEarnings: Double { engine.yearEarnings(now: now) }

    /// 预计今年总收入 = 月薪 × 12（固定目标值，与年度累计形成对照）。
    var yearTarget: Double { config.monthlySalary * 12 }
    var isWorkdayToday: Bool { engine.isWorkday(now) }

    /// 今天匹配的节假日名（如「春节」「国庆调休」）；普通日返回 nil。
    var todayHolidayName: String? { engine.holidayName(for: now) }

    /// 当年是否缺少法定节假日数据。
    /// 工作时段模式下为 true 时，节假日/调休会按星期几误算，需提示用户。
    /// 全天模式不依赖节假日，永远为 false。
    var isHolidayDataMissing: Bool {
        guard config.earningMode == .workHours else { return false }
        return !HolidayData.hasDataForCurrentYear(now: now)
    }

    // MARK: - 上瘾钩子

    /// 是否正在工作中（用于决定是否显示下班倒计时）。
    var isWorking: Bool { engine.dayState(now: now) == .working }

    /// 距下班的倒计时文案（如「2:34:10」）。非工作中返回 nil。
    /// 全天模式无「下班」概念，不显示。
    var clockOffCountdown: String? {
        guard config.earningMode == .workHours, isWorking else { return nil }
        let remaining = Int(engine.remainingWorkSeconds(now: now))
        guard remaining > 0 else { return nil }
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    /// 今日已赚的实物换算（如「≈ 13 杯奶茶」）。金额过小返回 nil。
    var earningsEquivalent: (icon: String, text: String)? {
        let amount = isWorkdayToday ? todayEarnings : monthEarnings
        return MoneyEquivalent.describe(amount)
    }

    // MARK: - 计时器

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    // MARK: - 持久化

    /// 写入共享存储，并（防抖后）通知 Widget 重新加载时间线。
    /// 落盘立即执行（本地廉价）；Widget 重载延迟合并，防止拖拽时高频刷新。
    private func save() {
        config.saveShared(to: defaults)
        scheduleWidgetReload()
    }

    /// 防抖触发 Widget 重载：0.6s 内的连续变更只在最后合并为一次。
    private func scheduleWidgetReload() {
        widgetReloadWork?.cancel()
        let work = DispatchWorkItem {
            WidgetCenter.shared.reloadAllTimelines()
        }
        widgetReloadWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
}
