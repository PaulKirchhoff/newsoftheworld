import AppKit
import SwiftUI

@MainActor
final class TickerPanelController {
    private let viewModel: TickerViewModel
    private var panel: NSPanel?
    private var desiredSize: NSSize

    var anchor: () -> NSStatusBarButton? = { nil }

    init(viewModel: TickerViewModel, initialSize: NSSize) {
        self.viewModel = viewModel
        self.desiredSize = initialSize
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func shutdown() {
        if let panel {
            panel.contentViewController = nil
            panel.close()
        }
        panel = nil
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        applyDesiredSize(to: panel)
        position(panel: panel)
        panel.orderFrontRegardless()
    }

    func updateGeometry(size: NSSize) {
        desiredSize = size
        guard let panel else { return }
        applyDesiredSize(to: panel)
    }

    static func panelHeight(forFontSize fontSize: Double) -> CGFloat {
        max(22, ceil(fontSize * 1.5) + 6)
    }

    /// Resizes the panel while keeping its current top-left corner pinned.
    /// AppKit measures window frames from the bottom-left, so to preserve
    /// the visual top we anchor `frame.maxY` instead of `frame.origin.y`.
    private func applyDesiredSize(to panel: NSPanel) {
        var frame = panel.frame
        let oldMaxY = frame.maxY
        frame.size = desiredSize
        frame.origin.y = oldMaxY - frame.size.height
        panel.setFrame(frame, display: true)
    }

    private func makePanel() -> NSPanel {
        let hosting = NSHostingController(rootView: TickerPanelView(viewModel: viewModel))

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: desiredSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.contentViewController = hosting
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }

    private func position(panel: NSPanel) {
        guard let buttonWindow = anchor()?.window else {
            panel.center()
            return
        }
        let buttonFrame = buttonWindow.frame
        let x = buttonFrame.midX - panel.frame.width / 2
        let y = buttonFrame.minY - panel.frame.height - 4
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
