import AppKit

extension NSImage {
    /// Create a resized copy of the image
    func resized(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: size),
             from: NSRect(origin: .zero, size: self.size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    /// Create a round-cornered version of the image
    func roundCorners(radius: CGFloat) -> NSImage {
        let rect = NSRect(origin: .zero, size: size)
        let newImage = NSImage(size: size)

        newImage.lockFocus()
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()
        draw(in: rect)
        newImage.unlockFocus()

        return newImage
    }
}
