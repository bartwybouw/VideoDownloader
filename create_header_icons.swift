#!/usr/bin/env swift

import Cocoa

// Create custom header icons with blue gradient and arrow design
func createHeaderIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    // Create blue gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0, green: 0.478, blue: 1, alpha: 1),
        NSColor(red: 0.353, green: 0.784, blue: 0.980, alpha: 1)
    ])
    
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let path = NSBezierPath(ovalIn: rect)
    gradient?.draw(in: path, angle: 135)
    
    // Create white arrow pointing down
    let arrowSize = CGFloat(size) * 0.5
    let arrowRect = NSRect(
        x: (CGFloat(size) - arrowSize) / 2,
        y: (CGFloat(size) - arrowSize) / 2,
        width: arrowSize,
        height: arrowSize
    )
    
    NSColor.white.setFill()
    
    // Draw down arrow shape
    let arrowPath = NSBezierPath()
    let centerX = arrowRect.midX
    let centerY = arrowRect.midY
    let arrowWidth = arrowSize * 0.6
    let arrowHeight = arrowSize * 0.6
    
    // Arrow shaft (top rectangle)
    let shaftWidth = arrowWidth * 0.3
    let shaftHeight = arrowHeight * 0.5
    arrowPath.appendRect(NSRect(
        x: centerX - shaftWidth/2,
        y: centerY,
        width: shaftWidth,
        height: shaftHeight
    ))
    
    // Arrow head (bottom triangle)
    let headWidth = arrowWidth * 0.8
    let headHeight = arrowHeight * 0.5
    arrowPath.move(to: NSPoint(x: centerX - headWidth/2, y: centerY))
    arrowPath.line(to: NSPoint(x: centerX + headWidth/2, y: centerY))
    arrowPath.line(to: NSPoint(x: centerX, y: centerY - headHeight))
    arrowPath.close()
    
    arrowPath.fill()
    
    image.unlockFocus()
    return image
}

// Save header icons
let sizes = [24, 48, 72]
let names = ["header-icon-24.png", "header-icon-48.png", "header-icon-72.png"]

for (size, name) in zip(sizes, names) {
    let icon = createHeaderIcon(size: size)
    
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    
    icon.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    
    NSGraphicsContext.restoreGraphicsState()
    
    let data = bitmapRep.representation(using: .png, properties: [:])
    let url = URL(fileURLWithPath: "/Users/bartwybouw/Documents/Claude/VideoDownloader/VideoDownloader/Assets.xcassets/HeaderIcon.imageset/\(name)")
    try! data!.write(to: url)
    
    print("Created \(name) (\(size)x\(size))")
}

print("Header icons created successfully!")