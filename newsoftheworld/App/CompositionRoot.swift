import AppKit

@MainActor
final class CompositionRoot {
    let tickerViewModel: TickerViewModel
    let settingsViewModel: SettingsViewModel
    let tickerPanelController: TickerPanelController
    let settingsWindowController: SettingsWindowController
    let statusBarController: StatusBarController
    let appearanceController: AppearanceController

    init() {
        let settingsRepo = UserDefaultsSettingsRepository()
        let sourcesRepo: NewsSourceRepository
        do {
            sourcesRepo = try JSONNewsSourceRepository()
        } catch {
            fatalError("Sources storage konnte nicht initialisiert werden: \(error)")
        }
        let secretStore = KeychainSecretStore()

        let appearance = AppearanceController()
        let tickerVM = TickerViewModel()
        let panelController = TickerPanelController(viewModel: tickerVM)

        let settingsVM = SettingsViewModel(
            settingsRepo: settingsRepo,
            sourcesRepo: sourcesRepo,
            secretStore: secretStore,
            onSettingsChange: { [tickerVM, appearance] settings in
                tickerVM.speed = settings.tickerSpeed
                appearance.apply(settings.appearance)
            }
        )

        tickerVM.speed = settingsVM.appSettings.tickerSpeed
        appearance.apply(settingsVM.appSettings.appearance)

        let settingsWindow = SettingsWindowController(viewModel: settingsVM)

        let statusBar = StatusBarController(
            onToggleTicker: { [panelController] button in
                panelController.toggle(relativeTo: button)
            },
            onOpenSettings: { [settingsWindow] in
                settingsWindow.show()
            },
            isTickerVisible: { [panelController] in
                panelController.isVisible
            }
        )

        self.tickerViewModel = tickerVM
        self.settingsViewModel = settingsVM
        self.tickerPanelController = panelController
        self.settingsWindowController = settingsWindow
        self.statusBarController = statusBar
        self.appearanceController = appearance

        // Placeholder bis T-040 (NewsFetcher) implementiert ist.
        tickerVM.display(SampleHeadlines.preview)

        if settingsVM.appSettings.autoShowTickerOnLaunch {
            panelController.show(relativeTo: statusBar.button)
        }
    }
}
