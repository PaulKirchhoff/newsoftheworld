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
        if panel == nil {
            // First show after launch: the NSStatusItem's button window
            // can take several runloop ticks to be placed in the menu
            // bar (especially under the Xcode debugger). Anchoring to an
            // empty frame would land the panel off-screen, so wait until
            // the button reports a real frame.
            awaitAnchorPlacement { [weak self] in
                self?.performShow()
            }
        } else {
            performShow()
        }
    }

    private func performShow() {
        let panel = panel ?? makePanel()
        self.panel = panel
        applyDesiredSize(to: panel)
        position(panel: panel)
        panel.orderFrontRegardless()
    }

    /// Polls the anchor's window frame until it reports a realistic
    /// menu-bar placement (non-zero size AND origin near the top of some
    /// screen), up to ~1 second. Falls through regardless on timeout so
    /// the user still sees something rather than a ghost panel.
    private func awaitAnchorPlacement(attempt: Int = 0, completion: @escaping () -> Void) {
        let maxAttempts = 60
        let frame = anchor()?.window?.frame ?? .zero
        if Self.isAnchorPlaced(frame) {
            completion()
            return
        }
        if attempt >= maxAttempts {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { [weak self] in
            self?.awaitAnchorPlacement(attempt: attempt + 1, completion: completion)
        }
    }

    /// A placed status-bar item sits near the top of some screen. Before
    /// macOS finishes placing it the frame is empty or parked at origin
    /// .zero with garbage size — distinguishable from the real thing.
    private static func isAnchorPlaced(_ frame: NSRect) -> Bool {
        guard frame.size.width > 0, frame.size.height > 0 else { return false }
        return NSScreen.screens.contains { screen in
            frame.minY >= screen.frame.maxY - 60
        }
    }

    func updateGeometry(fontSize: Double, widthPercent: Double) {
        let screen = panel?.screen ?? NSScreen.main
        desiredSize = NSSize(
            width: Self.panelWidth(forPercent: widthPercent, in: screen),
            height: Self.panelHeight(forFontSize: fontSize)
        )
        guard let panel else { return }
        applyDesiredSize(to: panel)
    }

    static func panelHeight(forFontSize fontSize: Double) -> CGFloat {
        max(22, ceil(fontSize * 1.5) + 6)
    }

    /// Converts a "fraction-of-screen" percentage (0…100) into an
    /// absolute pixel width. Falls back to the main screen if the panel
    /// hasn't been placed on a screen yet. A small floor keeps AppKit
    /// from having to render a zero-width window.
    static func panelWidth(forPercent percent: Double, in screen: NSScreen?) -> CGFloat {
        let screenWidth = (screen ?? NSScreen.main)?.frame.width ?? 1440
        let clamped = min(max(percent, 0), 100)
        return max(80, screenWidth * clamped / 100)
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
        guard
            let buttonWindow = anchor()?.window,
            Self.isAnchorPlaced(buttonWindow.frame)
        else {
            panel.center()
            return
        }
        let buttonFrame = buttonWindow.frame
        let origin = NSPoint(
            x: buttonFrame.midX - panel.frame.width / 2,
            y: buttonFrame.minY - panel.frame.height - 4
        )
        let target = NSRect(origin: origin, size: panel.frame.size)
        // Guard against multi-screen edge cases: if the resulting frame
        // is not on any visible screen, centre instead of disappearing.
        if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(target) }) {
            panel.setFrameOrigin(origin)
        } else {
            panel.center()
        }
    }
}
