import AppKit
import CoreGraphics

// 生成 1024×1024 App 图标：生动渐变风格（薄荷绿→青蓝），¥ + 上升趋势。
// 用法：swift make_icon.swift <输出路径>

let size = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("ctx") }

let S = CGFloat(size)

// 背景渐变（薄荷绿 → 青蓝，左上到右下），iOS 会自动加圆角遮罩，这里画满。
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let grad = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.12, green: 0.82, blue: 0.55, alpha: 1),
    CGColor(red: 0.04, green: 0.58, blue: 0.64, alpha: 1)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// 柔光圆（左上角高光，增加生动感）
let glow = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.22),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0)
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S*0.28, y: S*0.78), startRadius: 0,
                       endCenter: CGPoint(x: S*0.28, y: S*0.78), endRadius: S*0.55, options: [])

// 上升趋势折线（白色，半透明，传达「增长」）
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.30))
ctx.setLineWidth(S*0.045)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
let pts = [
    CGPoint(x: S*0.20, y: S*0.34),
    CGPoint(x: S*0.40, y: S*0.46),
    CGPoint(x: S*0.58, y: S*0.40),
    CGPoint(x: S*0.80, y: S*0.66),
]
ctx.beginPath()
ctx.move(to: pts[0])
for p in pts.dropFirst() { ctx.addLine(to: p) }
ctx.strokePath()
// 折线终点的箭头小三角
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.30))
let tip = pts.last!
ctx.beginPath()
ctx.move(to: CGPoint(x: tip.x, y: tip.y))
ctx.addLine(to: CGPoint(x: tip.x - S*0.085, y: tip.y))
ctx.addLine(to: CGPoint(x: tip.x, y: tip.y + S*0.085))
ctx.closePath()
ctx.fillPath()

// 中央 ¥ 符号（白色粗体，主体）
let yen = "¥"
let font = NSFont.systemFont(ofSize: S*0.56, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let str = NSAttributedString(string: yen, attributes: attrs)
let line = CTLineCreateWithAttributedString(str)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: (S - bounds.width)/2 - bounds.minX,
                           y: (S - bounds.height)/2 - bounds.minY)
// 轻微阴影增强层次
ctx.setShadow(offset: CGSize(width: 0, height: -S*0.012), blur: S*0.03,
              color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.18))
CTLineDraw(line, ctx)

// 导出 PNG
guard let img = ctx.makeImage() else { fatalError("img") }
let rep = NSBitmapImageRep(cgImage: img)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
