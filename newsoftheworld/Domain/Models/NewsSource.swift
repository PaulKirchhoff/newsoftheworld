import Foundation

struct NewsSource: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var type: SourceType
    var endpointURL: URL
    var isEnabled: Bool
    var refreshIntervalSeconds: Int
    var hasAPIKey: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: SourceType,
        endpointURL: URL,
        isEnabled: Bool = true,
        refreshIntervalSeconds: Int = 300,
        hasAPIKey: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.endpointURL = endpointURL
        self.isEnabled = isEnabled
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.hasAPIKey = hasAPIKey
    }
}
