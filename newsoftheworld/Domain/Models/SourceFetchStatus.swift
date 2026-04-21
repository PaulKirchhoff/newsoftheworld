import Foundation

struct SourceFetchStatus: Equatable, Sendable {
    var lastFetchAt: Date?
    var lastSuccessAt: Date?
    var lastErrorMessage: String?
    var consecutiveFailures: Int
    var lastItemCount: Int

    nonisolated init(
        lastFetchAt: Date? = nil,
        lastSuccessAt: Date? = nil,
        lastErrorMessage: String? = nil,
        consecutiveFailures: Int = 0,
        lastItemCount: Int = 0
    ) {
        self.lastFetchAt = lastFetchAt
        self.lastSuccessAt = lastSuccessAt
        self.lastErrorMessage = lastErrorMessage
        self.consecutiveFailures = consecutiveFailures
        self.lastItemCount = lastItemCount
    }
}
