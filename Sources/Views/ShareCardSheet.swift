import SwiftUI

/// 分享战绩卡的 sheet：展示卡片预览 + 分享按钮。
///
/// 进入时冻结当前金额快照（不随秒跳动），保证预览与分享出去的图一致。
struct ShareCardSheet: View {
    let todayEarnings: Double
    let monthEarnings: Double
    let yearEarnings: Double
    let isWorkday: Bool
    let brand: BrandTheme

    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareCardImage?

    /// 卡片日期文案（生成时定格）。
    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日"
        return f.string(from: Date())
    }

    private var card: ShareCardView {
        ShareCardView(
            todayEarnings: todayEarnings,
            monthEarnings: monthEarnings,
            yearEarnings: yearEarnings,
            isWorkday: isWorkday,
            dateText: dateText,
            brand: brand
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // 卡片预览（带圆角与投影，呈现「成品」感）
                card
                    .clipShape(RoundedRectangle(cornerRadius: Brand.cornerLarge))
                    .shadow(color: .black.opacity(0.2), radius: 18, y: 8)

                Spacer()

                // 分享按钮
                if let shareItem {
                    ShareLink(
                        item: shareItem,
                        preview: SharePreview("我的摸鱼战绩", image: shareItem.image)
                    ) {
                        shareButtonLabel
                    }
                } else {
                    // 渲染中/失败兜底
                    shareButtonLabel.opacity(0.5)
                }
            }
            .padding()
            .navigationTitle("分享战绩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                // sheet 出现后渲染图片（避免阻塞弹出动画）。
                prepareShareItem()
            }
        }
    }

    private var shareButtonLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
            Text("分享这张卡片")
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(brand.heroGradient, in: RoundedRectangle(cornerRadius: Brand.cornerMedium))
    }

    @MainActor
    private func prepareShareItem() {
        guard shareItem == nil else { return }
        shareItem = ShareCardRenderer.renderShareItem(card)
    }
}
