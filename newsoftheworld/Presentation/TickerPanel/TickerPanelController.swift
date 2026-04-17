import AppKit
import SwiftUI

@MainActor
final class TickerPanelController {
    private let viewModel: TickerViewModel
    private var panel: NSPanel?

    init(viewModel: TickerViewModel) {
        self.viewModel = viewModel
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(relativeTo statusButton: NSStatusBarButton?) {
        if isVisible {
            hide()
        } else {
            show(relativeTo: statusButton)
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func show(relativeTo statusButton: NSStatusBarButton?) {
        let panel = panel ?? makePanel()
        self.panel = panel
        position(panel: panel, relativeTo: statusButton)
        panel.orderFrontRegardless()
    }

    private func makePanel() -> NSPanel {
        let hosting = NSHostingController(rootView: TickerPanelView(viewModel: viewModel))
        hosting.sizingOptions = [.preferredContentSize]

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 44),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: true
        )
        panel.contentViewController = hosting
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        return panel
    }

    private func position(panel: NSPanel, relativeTo statusButton: NSStatusBarButton?) {
        guard let buttonWindow = statusButton?.window else {
            panel.center()
            return
        }
        let buttonFrame = buttonWindow.frame
        let panelSize = panel.frame.size
        let x = buttonFrame.midX - panelSize.width / 2
        let y = buttonFrame.minY - panelSize.height - 4
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
