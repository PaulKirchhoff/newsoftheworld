import Foundation
import Observation

@MainActor
@Observable
final class TickerViewModel {
    var state: TickerState = .idle
    var speed: Double = 60
    var separator: String = "   •   "

    func display(_ items: [NewsItem]) {
        state = items.isEmpty ? .empty : .loaded(items)
    }

    func setLoading() {
        state = .loading
    }

    func setError(_ message: String) {
        state = .error(message)
    }
}
