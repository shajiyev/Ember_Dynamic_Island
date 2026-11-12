// Builds the macOS app icon from assets/Ember_logo.png.
// That PNG is exported from the master, assets/Ember_logo.svg (see docs/specs/logo.md).
//
// A Mac app icon is a rounded square that fills 824 of the 1024 pixels, with a soft
// shadow. macOS does not round the corners itself, so the shape is drawn here.
//
// Usage, from the repository root:
//     swift scripts/make-app-icon.swift

import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let logoURL = root.appendingPathComponent("assets/Ember_logo.png")
let iconSetURL = root.appendingPathComponent("Ember/Assets.xcassets/AppIcon.appiconset")
let fullSizeURL = root.appendingPathComponent("assets/Ember_app_icon.png")

guard let logo = NSImage(contentsOf: logoURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Cannot read \(logoURL.path). Run this from the repository root.")
}

func renderIcon(from logo: CGImage, pixels: Int) -> CGImage {
    let size = CGFloat(pixels)
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high

    let inset = size * 100 / 1024
    let body = CGRect(x: 0, y: 0, width: size, height: size).insetBy(dx: inset, dy: inset)
    let radius = body.width * 0.2237
    let outline = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Soft shadow under the body.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 10 / 1024), blur: size * 20 / 1024,
                      color: CGColor(gray: 0, alpha: 0.3))
    context.addPath(outline)
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.fillPath()
    context.restoreGState()

    // The logo, cut to the rounded square.
    context.addPath(outline)
    context.clip()
    context.draw(logo, in: body)

    // A thin light edge, brighter at the top, so the dark icon stands out on a dark Dock.
    let edgeWidth = body.width * 6 / 1600
    let edgeRadius = radius - edgeWidth / 2
    let edge = CGPath(roundedRect: body.insetBy(dx: edgeWidth / 2, dy: edgeWidth / 2),
                      cornerWidth: edgeRadius, cornerHeight: edgeRadius, transform: nil)
    context.addPath(edge)
    context.setLineWidth(edgeWidth)
    context.replacePathWithStrokedPath()
    context.clip()
    let edgeColors = [CGColor(gray: 1, alpha: 0.22), CGColor(gray: 1, alpha: 0.04)] as CFArray
    let edgeGradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: edgeColors,
                                  locations: [0, 1])!
    context.drawLinearGradient(edgeGradient, start: CGPoint(x: 0, y: body.maxY),
                               end: CGPoint(x: 0, y: body.minY), options: [])
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try data.write(to: url)
}

// The sizes macOS asks for: each point size at 1x and 2x.
let pointSizes = [16, 32, 128, 256, 512]

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in pointSizes {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try writePNG(renderIcon(from: logo, pixels: points * scale), to: iconSetURL.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: iconSetURL.appendingPathComponent("Contents.json"))

try writePNG(renderIcon(from: logo, pixels: 1024), to: fullSizeURL)
print("Wrote \(images.count) icon sizes to \(iconSetURL.lastPathComponent) and \(fullSizeURL.lastPathComponent)")
