import SwiftUI
import UniformTypeIdentifiers

/// 把 `ShareCardView` 渲染成图片，供分享。
///
/// 用 iOS 16+ 的 `ImageRenderer`，在主线程同步渲染（卡片是静态快照，开销小）。
enum ShareCardRenderer {

    /// 渲染战绩卡为高清 UIImage。scale 默认 3，输出约 1080×1350。
    @MainActor
    static func render(_ card: ShareCardView, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        return renderer.uiImage
    }

    /// 渲染为可分享的图片载体（PNG 数据），失败返回 nil。
    @MainActor
    static func renderShareItem(_ card: ShareCardView, scale: CGFloat = 3) -> ShareCardImage? {
        guard let uiImage = render(card, scale: scale),
              let data = uiImage.pngData() else { return nil }
        return ShareCardImage(data: data, image: Image(uiImage: uiImage))
    }
}

/// 可被 ShareLink 分享的图片载体。
///
/// 导出为 **PNG 图片类型**（而非文件 URL），这样微信等 App 会识别为图片消息、
/// 直接贴图展示，而不是当成需要点开的文件。
struct ShareCardImage: Transferable {
    let data: Data
    let image: Image

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.data
        }
        .suggestedFileName("摸鱼战绩.png")
    }
}

