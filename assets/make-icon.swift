import AppKit

let canvas: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvas, height: canvas))
image.lockFocus()

let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let squircle = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
let top = NSColor(calibratedRed: 0.42, green: 0.36, blue: 0.91, alpha: 1)
let bottom = NSColor(calibratedRed: 0.24, green: 0.17, blue: 0.55, alpha: 1)
NSGradient(starting: top, ending: bottom)!.draw(in: squircle, angle: -90)

let config = NSImage.SymbolConfiguration(pointSize: 430, weight: .medium)
let symbol = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(config)!
let tinted = NSImage(size: symbol.size)
tinted.lockFocus()
symbol.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
NSColor.white.set()
NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
tinted.unlockFocus()

let scale = (rect.height * 0.52) / tinted.size.height
let drawSize = NSSize(width: tinted.size.width * scale, height: tinted.size.height * scale)
let origin = NSPoint(x: rect.midX - drawSize.width / 2, y: rect.midY - drawSize.height / 2)
tinted.draw(in: NSRect(origin: origin, size: drawSize))

image.unlockFocus()

let tiff = image.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
rep.size = NSSize(width: canvas, height: canvas)
let png = rep.representation(using: .png, properties: [:])!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
try! png.write(to: out)
