import AppKit
import os

@MainActor
final class CompositionRoot {
    let tickerViewModel: TickerViewModel
    let settingsViewModel: SettingsViewModel
    let tickerPanelController: TickerPanelController
    let settingsWindowController: SettingsWindowController
    let statusBarController: StatusBarController
    let appearanceController: AppearanceController
    let refreshCoordinator: RefreshCoordinator
    let sourceStatusStore: SourceStatusStore

    init() {
        let settingsRepo = UserDefaultsSettingsRepository()
        let sourcesRepo: NewsSourceRepository
        do {
            sourcesRepo = try JSONNewsSourceRepository()
        } catch {
            AppLog.sources.critical("Sources storage init failed: \(error.localizedDescription, privacy: .public)")
            fatalError("Sources storage konnte nicht initialisiert werden: \(error)")
        }
        let secretStore = KeychainSecretStore()
        let httpClient = URLSessionHTTPClient()
        let launchAtLogin: LaunchAtLoginService = SMAppServiceLaunchAtLoginAdapter()

        let xmlFetcher = XMLFeedFetcher(httpClient: httpClient)
        let jsonFetcher = JSONFeedFetcher(httpClient: httpClient)
        let resolver = FetcherResolver(fetchers: [
            .rss: xmlFetcher,
            .atom: xmlFetcher,
            .jsonAPI: jsonFetcher,
        ])
        let sourceTester = DefaultSourceTester(resolver: resolver)

        let appearance = AppearanceController()
        let tickerVM = TickerViewModel()
        let panelController = TickerPanelController(viewModel: tickerVM)
        let statusStore = SourceStatusStore()

        let refreshCoordinator = RefreshCoordinator(
            resolver: resolver,
            sourcesRepo: sourcesRepo,
            secretStore: secretStore,
            tickerVM: tickerVM,
            statusStore: statusStore
        )

        let settingsVM = SettingsViewModel(
            settingsRepo: settingsRepo,
            sourcesRepo: sourcesRepo,
            secretStore: secretStore,
            launchAtLoginService: launchAtLogin,
            sourceTester: sourceTester,
            statusStore: statusStore,
            onSettingsChange: { [tickerVM, appearance] settings in
                tickerVM.speed = settings.tickerSpeed
                appearance.apply(settings.appearance)
            },
            onSourcesChange: { [refreshCoordinator] in
                refreshCoordinator.triggerRefresh()
            },
            onRefreshRequest: { [refreshCoordinator] id in
                refreshCoordinator.refresh(sourceID: id)
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
        self.refreshCoordinator = refreshCoordinator
        self.sourceStatusStore = statusStore

        AppLog.app.info("CompositionRoot initialised")
        refreshCoordinator.start()

        if settingsVM.appSettings.autoShowTickerOnLaunch {
            panelController.show(relativeTo: statusBar.button)
        }
    }
}
