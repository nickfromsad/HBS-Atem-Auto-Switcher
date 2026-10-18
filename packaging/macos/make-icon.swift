// Renders the macOS app icon: the HOF "CAM1" logo (the same icon the Windows exe uses, embedded
// in atem_switcher.pyw) on a dark rounded-square HBS tile. macOS 26 puts icons that are not this
// rounded-square shape on a white plate, so the round logo can't be used as-is.
//   swift packaging/macos/make-icon.swift <logo-256.png> <output.iconset>
import AppKit

let logo = NSImage(contentsOfFile: CommandLine.arguments[1])!
let iconset = URL(fileURLWithPath: CommandLine.arguments[2])

func render(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    // macOS icon grid: an 824/1024 rounded square.
    let px = size / 1024
    let tile = NSRect(x: 100 * px, y: 100 * px, width: 824 * px, height: 824 * px)
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185 * px, yRadius: 185 * px)
    NSGradient(starting: NSColor(srgbRed: 0.17, green: 0.17, blue: 0.17, alpha: 1),
               ending: NSColor(srgbRed: 0.08, green: 0.08, blue: 0.08, alpha: 1))!.draw(in: tilePath, angle: -90)
    NSColor(white: 1, alpha: 0.08).setStroke()
    tilePath.lineWidth = 4 * px
    tilePath.stroke()

    // The logo, badge included, slightly larger than the tile's inner area so the badge reaches the edge.
    logo.draw(in: NSRect(x: 160 * px, y: 160 * px, width: 704 * px, height: 704 * px))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try render(size: CGFloat(base * scale)).representation(using: .png, properties: [:])!
            .write(to: iconset.appendingPathComponent(name))
    }
}
print("wrote \(iconset.path)")
