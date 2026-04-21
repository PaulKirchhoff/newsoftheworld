import Foundation
import os

@MainActor
final class RefreshCoordinator {
    private let resolver: FetcherResolver
    private let sourcesRepo: NewsSourceRepository
    private let secretStore: SecretStore
    private let tickerVM: TickerViewModel
    private let statusStore: SourceStatusStore

    private let minimumIntervalSeconds: Int = 30

    private var sourceTasks: [UUID: Task<Void, Never>] = [:]
    private var itemsBySource: [UUID: [NewsItem]] = [:]

    init(
        resolver: FetcherResolver,
        sourcesRepo: NewsSourceRepository,
        secretStore: SecretStore,
        tickerVM: TickerViewModel,
        statusStore: SourceStatusStore
    ) {
        self.resolver = resolver
        self.sourcesRepo = sourcesRepo
        self.secretStore = secretStore
        self.tickerVM = tickerVM
        self.statusStore = statusStore
    }

    func start() {
        reconcile()
    }

    func triggerRefresh() {
        reconcile()
    }

    func refresh(sourceID: UUID) {
        guard
            let sources = try? sourcesRepo.load(),
            let source = sources.first(where: { $0.id == sourceID && $0.isEnabled })
        else { return }
        Task { [weak self] in
            await self?.fetchOnce(for: source)
        }
    }

    func stop() {
        for task in sourceTasks.values { task.cancel() }
        sourceTasks.removeAll()
        itemsBySource.removeAll()
        updateTickerState()
    }

    private func reconcile() {
        let sources: [NewsSource]
        do {
            sources = try sourcesRepo.load()
        } catch {
            AppLog.sources.error("Sources konnten nicht geladen werden: \(error.localizedDescription, privacy: .public)")
            sources = []
        }
        let activeByID = Dictionary(
            uniqueKeysWithValues: sources.filter(\.isEnabled).map { ($0.id, $0) }
        )

        for id in Array(sourceTasks.keys) where activeByID[id] == nil {
            sourceTasks[id]?.cancel()
            sourceTasks.removeValue(forKey: id)
            itemsBySource.removeValue(forKey: id)
            statusStore.remove(sourceID: id)
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
            let message = "Kein Fetcher für Typ \(source.type.localizedName)"
            AppLog.fetch.error("\(message, privacy: .public) [source=\(source.id.uuidString, privacy: .public)]")
            statusStore.recordFailure(sourceID: source.id, message: message)
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
            statusStore.recordSuccess(sourceID: source.id, itemCount: items.count)
            AppLog.fetch.debug("Fetch ok [source=\(source.id.uuidString, privacy: .public), count=\(items.count, privacy: .public)]")
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            statusStore.recordFailure(sourceID: source.id, message: message)
            AppLog.fetch.warning("Fetch failed [source=\(source.id.uuidString, privacy: .public)]: \(message, privacy: .public)")
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

        let errorMessages = statusStore.statuses.values.compactMap { $0.lastErrorMessage }
        if let firstError = errorMessages.first {
            tickerVM.setError(firstError)
            return
        }

        tickerVM.setLoading()
    }
}
