import AppKit
import SwiftUI

@MainActor
final class ReaderPanelController {
    private var panel: ReaderPanel?

    func show(controller: ReaderController, metrics: DisplayMetrics) {
        let panel = self.panel ?? ReaderPanelFactory.make(frame: metrics.canvasFrame)
        self.panel = panel
        panel.setFrame(metrics.canvasFrame, display: true)
        panel.contentView = NSHostingView(rootView: ReaderRootView(controller: controller))
        panel.orderFrontRegardless()
    }

    func takeFocus() {
        NSApp.activate()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func handleDisplayChange(controller: ReaderController) {
        guard controller.presentationState != .hidden else { return }
        controller.closeImmediately()
    }
}
