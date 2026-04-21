import Foundation

@MainActor
final class RefreshCoordinator {
    private let resolver: FetcherResolver
    private let sourcesRepo: NewsSourceRepository
    private let secretStore: SecretStore
    private let tickerVM: TickerViewModel

    private let minimumIntervalSeconds: Int = 30

    private var sourceTasks: [UUID: Task<Void, Never>] = [:]
    private var itemsBySource: [UUID: [NewsItem]] = [:]
    private var errorsBySource: [UUID: String] = [:]

    init(
        resolver: FetcherResolver,
        sourcesRepo: NewsSourceRepository,
        secretStore: SecretStore,
        tickerVM: TickerViewModel
    ) {
        self.resolver = resolver
        self.sourcesRepo = sourcesRepo
        self.secretStore = secretStore
        self.tickerVM = tickerVM
    }

    func start() {
        reconcile()
    }

    func triggerRefresh() {
        reconcile()
    }

    func stop() {
        for task in sourceTasks.values { task.cancel() }
        sourceTasks.removeAll()
        itemsBySource.removeAll()
        errorsBySource.removeAll()
        updateTickerState()
    }

    private func reconcile() {
        let sources = (try? sourcesRepo.load()) ?? []
        let activeByID = Dictionary(
            uniqueKeysWithValues: sources.filter(\.isEnabled).map { ($0.id, $0) }
        )

        for id in Array(sourceTasks.keys) where activeByID[id] == nil {
            sourceTasks[id]?.cancel()
            sourceTasks.removeValue(forKey: id)
            itemsBySource.removeValue(forKey: id)
            errorsBySource.removeValue(forKey: id)
        }

        for (id, source) in activeByID {
            sourceTasks[id]?.cancel()
            sourceTasks[id] = Task { [weak self] in
                await self?.runLoop(source: source)
            }
        }

        updateTickerState()
    }

    private func runLoop(source: NewsSource) async {
        while !Task.isCancelled {
            await fetchOnce(for: source)
            let seconds = max(minimumIntervalSeconds, source.refreshIntervalSeconds)
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
        }
    }

    private func fetchOnce(for source: NewsSource) async {
        guard let fetcher = resolver.fetcher(for: source.type) else {
            errorsBySource[source.id] = "Kein Fetcher für Typ \(source.type.localizedName)"
            updateTickerState()
            return
        }

        let apiKey: String?
        if source.hasAPIKey {
            apiKey = try? secretStore.secret(for: "source.\(source.id.uuidString)")
        } else {
            apiKey = nil
        }

        do {
            let items = try await fetcher.fetch(source: source, apiKey: apiKey)
            guard !Task.isCancelled else { return }
            itemsBySource[source.id] = items
            errorsBySource.removeValue(forKey: source.id)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorsBySource[source.id] = message
        }
        updateTickerState()
    }

    private func updateTickerState() {
        if sourceTasks.isEmpty {
            tickerVM.state = .idle
            return
        }

        let merged = itemsBySource.values
            .flatMap { $0 }
            .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }

        if !merged.isEmpty {
            tickerVM.display(merged)
            return
        }

        if let firstError = errorsBySource.values.first {
            tickerVM.setError(firstError)
            return
        }

        tickerVM.setLoading()
    }
}
