import XCTest
import SwiftUI
@testable import SalaryCount

/// 分享战绩卡渲染冒烟测试：验证卡片能渲染出非空图片，并落盘一张供人工核对。
final class ShareCardTests: XCTestCase {

    @MainActor
    func testShareCardRendersNonEmptyImage() throws {
        let card = ShareCardView(
            todayEarnings: 234.56,
            monthEarnings: 4567.89,
            yearEarnings: 28900,
            isWorkday: true,
            dateText: "2026年6月6日",
            brand: .green
        )
        let image = ShareCardRenderer.render(card, scale: 3)
        let img = try XCTUnwrap(image, "卡片应渲染出图片")
        XCTAssertGreaterThan(img.size.width, 0)
        XCTAssertGreaterThan(img.size.height, 0)

        // 落盘供人工核对（CI 环境可忽略）。
        if let data = img.pngData() {
            let url = URL(fileURLWithPath: "/tmp/salary-card-workday.png")
            try? data.write(to: url)
        }
    }

    @MainActor
    func testShareCardRendersForEachTheme() throws {
        // 四套主题都应渲染成功，防止某主题色取值崩溃。
        for theme in AccentTheme.allCases {
            let card = ShareCardView(
                todayEarnings: 100, monthEarnings: 2000, yearEarnings: 12000,
                isWorkday: false, dateText: "2026年6月6日",
                brand: BrandTheme(accent: theme)
            )
            XCTAssertNotNil(ShareCardRenderer.render(card, scale: 2),
                            "\(theme.rawValue) 主题卡片应渲染成功")
        }
    }
}
