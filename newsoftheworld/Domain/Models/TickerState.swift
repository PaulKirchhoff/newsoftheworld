import Foundation

enum TickerState: Equatable, Sendable {
    case idle
    case loading
    case empty
    case loaded([NewsItem])
    case error(String)
}
