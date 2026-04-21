import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var appSettings: AppSettings
    var sources: [NewsSource]
    var lastError: String?

    private let settingsRepo: SettingsRepository
    private let sourcesRepo: NewsSourceRepository
    private let secretStore: SecretStore
    private let onSettingsChange: (AppSettings) -> Void
    private let onSourcesChange: () -> Void

    init(
        settingsRepo: SettingsRepository,
        sourcesRepo: NewsSourceRepository,
        secretStore: SecretStore,
        onSettingsChange: @escaping (AppSettings) -> Void,
        onSourcesChange: @escaping () -> Void
    ) {
        self.settingsRepo = settingsRepo
        self.sourcesRepo = sourcesRepo
        self.secretStore = secretStore
        self.onSettingsChange = onSettingsChange
        self.onSourcesChange = onSourcesChange
        self.appSettings = settingsRepo.load()

        do {
            self.sources = try sourcesRepo.load()
        } catch {
            self.sources = []
            self.lastError = "Quellen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    func persistSettings() {
        settingsRepo.save(appSettings)
        onSettingsChange(appSettings)
    }

    func addSource(
        name: String,
        type: SourceType,
        url: URL,
        apiKey: String?,
        isEnabled: Bool,
        refreshIntervalSeconds: Int
    ) {
        var source = NewsSource(
            name: name,
            type: type,
            endpointURL: url,
            isEnabled: isEnabled,
            refreshIntervalSeconds: refreshIntervalSeconds
        )
        if let apiKey, !apiKey.isEmpty {
            do {
                try secretStore.setSecret(apiKey, for: keychainReference(for: source.id))
                source.hasAPIKey = true
            } catch {
                lastError = "API-Key konnte nicht gespeichert werden: \(error.localizedDescription)"
                return
            }
        }
        sources.append(source)
        persistSources()
    }

    func updateSource(
        id: UUID,
        name: String,
        type: SourceType,
        url: URL,
        isEnabled: Bool,
        refreshIntervalSeconds: Int,
        apiKeyUpdate: APIKeyUpdate
    ) {
        guard let index = sources.firstIndex(where: { $0.id == id }) else { return }
        var source = sources[index]
        source.name = name
        source.type = type
        source.endpointURL = url
        source.isEnabled = isEnabled
        source.refreshIntervalSeconds = refreshIntervalSeconds

        let reference = keychainReference(for: id)
        switch apiKeyUpdate {
        case .unchanged:
            break
        case .cleared:
            try? secretStore.removeSecret(for: reference)
            source.hasAPIKey = false
        case .replaced(let newValue):
            if newValue.isEmpty {
                try? secretStore.removeSecret(for: reference)
                source.hasAPIKey = false
            } else {
                do {
                    try secretStore.setSecret(newValue, for: reference)
                    source.hasAPIKey = true
                } catch {
                    lastError = "API-Key konnte nicht gespeichert werden: \(error.localizedDescription)"
                    return
                }
            }
        }

        sources[index] = source
        persistSources()
    }

    func deleteSource(id: UUID) {
        try? secretStore.removeSecret(for: keychainReference(for: id))
        sources.removeAll { $0.id == id }
        persistSources()
    }

    private func persistSources() {
        do {
            try sourcesRepo.save(sources)
            onSourcesChange()
        } catch {
            lastError = "Quellen konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    private func keychainReference(for id: UUID) -> String {
        "source.\(id.uuidString)"
    }
}

enum APIKeyUpdate {
    case unchanged
    case cleared
    case replaced(String)
}
