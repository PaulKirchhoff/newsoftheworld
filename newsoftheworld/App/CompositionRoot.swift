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
        let initialSettings = settingsRepo.load()

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
        tickerVM.speed = initialSettings.tickerSpeed
        tickerVM.fontSize = initialSettings.tickerFontSize
        appearance.apply(initialSettings.appearance)

        let initialPanelSize = NSSize(
            width: initialSettings.tickerPanelWidth,
            height: TickerPanelController.panelHeight(forFontSize: initialSettings.tickerFontSize)
        )
        let panelController = TickerPanelController(
            viewModel: tickerVM,
            initialSize: initialPanelSize
        )
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
            onSettingsChange: { [tickerVM, appearance, panelController] settings in
                tickerVM.speed = settings.tickerSpeed
                tickerVM.fontSize = settings.tickerFontSize
                appearance.apply(settings.appearance)
                panelController.updateGeometry(
                    size: NSSize(
                        width: settings.tickerPanelWidth,
                        height: TickerPanelController.panelHeight(forFontSize: settings.tickerFontSize)
                    )
                )
            },
            onSourcesChange: { [refreshCoordinator] in
                refreshCoordinator.triggerRefresh()
            },
            onRefreshRequest: { [refreshCoordinator] id in
                refreshCoordinator.refresh(sourceID: id)
            }
        )

        let settingsWindow = SettingsWindowController(viewModel: settingsVM)

        let statusBar = StatusBarController(
            onToggleTicker: { [panelController] in
                panelController.toggle()
            },
            onOpenSettings: { [settingsWindow] in
                settingsWindow.show()
            },
            isTickerVisible: { [panelController] in
                panelController.isVisible
            }
        )

        panelController.anchor = { [weak statusBar] in statusBar?.button }

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
            panelController.show()
        }
    }
}
