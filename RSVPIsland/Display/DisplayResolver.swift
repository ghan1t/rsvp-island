import AppKit

@MainActor
final class DisplayResolver {
    func resolve(originatingWindowFrame: CGRect?) -> DisplayMetrics? {
        let screens = NSScreen.screens
        let selected: NSScreen?
        if let frame = originatingWindowFrame {
            selected = screens.first { $0.frame.contains(CGPoint(x: frame.midX, y: frame.midY)) }
                ?? screenAtMouse(in: screens)
        } else {
            selected = screenAtMouse(in: screens)
        }
        guard let screen = selected ?? NSScreen.main ?? screens.first else { return nil }
        return metrics(for: screen)
    }

    private func screenAtMouse(in screens: [NSScreen]) -> NSScreen? {
        screens.first { $0.frame.contains(NSEvent.mouseLocation) }
    }

    private func metrics(for screen: NSScreen) -> DisplayMetrics {
        let hasNotch = screen.safeAreaInsets.top > 0
        let calculatedWidth: CGFloat? = if let leftArea = screen.auxiliaryTopLeftArea,
                                            let rightArea = screen.auxiliaryTopRightArea {
            screen.frame.width - leftArea.width - rightArea.width
        } else {
            nil
        }
        let notchSize: CGSize? = if hasNotch {
            if let calculatedWidth, calculatedWidth > 0 {
                CGSize(width: calculatedWidth, height: max(screen.safeAreaInsets.top, 1))
            } else {
                CGSize(width: 185, height: max(screen.safeAreaInsets.top, 32))
            }
        } else {
            nil
        }
        let canvasWidth = min(640, screen.frame.width)
        let canvasHeight = min(200, screen.frame.height)
        let canvas = CGRect(
            x: floor(screen.frame.midX - canvasWidth / 2),
            y: screen.frame.maxY - canvasHeight,
            width: canvasWidth,
            height: canvasHeight
        )
        return DisplayMetrics(
            screen: screen,
            hasPhysicalNotch: hasNotch,
            physicalNotchSize: notchSize,
            canvasFrame: canvas,
            maximumSurfaceWidth: max(1, min(600, screen.frame.width - 40))
        )
    }
}
