import AppKit

struct DisplayMetrics {
    let screen: NSScreen
    let hasPhysicalNotch: Bool
    let physicalNotchSize: CGSize?
    let canvasFrame: CGRect
    let maximumSurfaceWidth: CGFloat
}
