import Foundation
import Observation

@MainActor
@Observable
final class SourceStatusStore {
    var statuses: [UUID: SourceFetchStatus] = [:]

    func recordSuccess(sourceID: UUID, itemCount: Int, at date: Date = Date()) {
        var status = statuses[sourceID] ?? SourceFetchStatus()
        status.lastFetchAt = date
        status.lastSuccessAt = date
        status.lastErrorMessage = nil
        status.consecutiveFailures = 0
        status.lastItemCount = itemCount
        statuses[sourceID] = status
    }

    func recordFailure(sourceID: UUID, message: String, at date: Date = Date()) {
        var status = statuses[sourceID] ?? SourceFetchStatus()
        status.lastFetchAt = date
        status.lastErrorMessage = message
        status.consecutiveFailures += 1
        statuses[sourceID] = status
    }

    func remove(sourceID: UUID) {
        statuses.removeValue(forKey: sourceID)
    }
}
