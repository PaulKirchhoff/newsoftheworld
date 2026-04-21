import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let statusMenu = NSMenu()
    private let onToggleTicker: () -> Void
    private let onOpenSettings: () -> Void
    private let isTickerVisible: () -> Bool

    init(
        onToggleTicker: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        isTickerVisible: @escaping () -> Bool
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onToggleTicker = onToggleTicker
        self.onOpenSettings = onOpenSettings
        self.isTickerVisible = isTickerVisible
        super.init()
        configure()
    }

    var button: NSStatusBarButton? { statusItem.button }

    private func configure() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "newspaper",
                accessibilityDescription: "News of the World"
            )
            button.imagePosition = .imageOnly
        }

        statusMenu.delegate = self

        let tickerItem = NSMenuItem(
            title: "Ticker anzeigen",
            action: #selector(didSelectTicker),
            keyEquivalent: ""
        )
        tickerItem.target = self
        statusMenu.addItem(tickerItem)

        statusMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Einstellungen…",
            action: #selector(didSelectSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        statusMenu.addItem(settingsItem)

        statusMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Beenden",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusMenu.addItem(quitItem)

        statusItem.menu = statusMenu
    }

    func menuWillOpen(_ menu: NSMenu) {
        if let tickerItem = menu.items.first {
            tickerItem.title = isTickerVisible() ? "Ticker verbergen" : "Ticker anzeigen"
        }
    }

    @objc private func didSelectTicker() {
        onToggleTicker()
    }

    @objc private func didSelectSettings() {
        onOpenSettings()
    }
}
