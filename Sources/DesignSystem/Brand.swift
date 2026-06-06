import SwiftUI

/// 共享设计语言：品牌渐变、色彩、字体。
///
/// App 主界面与 Widget 都引用同一套，保证视觉统一（生动渐变风格）。
/// 仅依赖 SwiftUI，可在 App 与 Widget extension 两个 target 编译。
enum Brand {

    // MARK: - 品牌色

    /// 主色：清新薄荷绿（代表「钱在生长」的积极感）。
    static let primary = Color(red: 0.10, green: 0.78, blue: 0.52)
    /// 次色：青蓝（与主色构成渐变的另一端）。
    static let secondary = Color(red: 0.05, green: 0.62, blue: 0.66)
    /// 强调暖色：用于「钱在涨」的跳动提示。
    static let accentWarm = Color(red: 1.0, green: 0.78, blue: 0.30)

    // MARK: - 渐变

    /// 主渐变：今日 hero 卡片背景（左上→右下）。
    static let heroGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 休息日渐变：暖橙，区别于工作日的绿。
    static let restGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.62, blue: 0.30),
                 Color(red: 0.96, green: 0.44, blue: 0.32)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 进度弧/进度条渐变。
    static let progressGradient = LinearGradient(
        colors: [accentWarm, primary],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 根据「是否工作日」选择主渐变。
    static func heroGradient(isWorkday: Bool) -> LinearGradient {
        isWorkday ? heroGradient : restGradient
    }

    // MARK: - 圆角

    static let cornerLarge: CGFloat = 24
    static let cornerMedium: CGFloat = 18
    static let cornerSmall: CGFloat = 14
}

// MARK: - 字体便捷

extension Font {
    /// 大金额数字（圆体、等宽数字感）。
    static func moneyHero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    /// 中等金额。
    static let moneyTitle = Font.system(.title3, design: .rounded).weight(.semibold)
}
