import Foundation

enum SourceTestResult: Sendable, Equatable {
    case success(itemCount: Int)
    case failure(String)
}

protocol SourceTester: Sendable {
    func test(name: String, type: SourceType, url: URL, apiKey: String?) async -> SourceTestResult
}
