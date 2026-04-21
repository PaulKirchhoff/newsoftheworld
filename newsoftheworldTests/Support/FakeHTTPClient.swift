import Foundation
@testable import newsoftheworld

nonisolated
final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    private let payload: Data
    private let response: URLResponse

    private let lock = NSLock()
    private var _lastRequest: URLRequest?

    init(data: Data, response: URLResponse) {
        self.payload = data
        self.response = response
    }

    var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return _lastRequest
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        _lastRequest = request
        lock.unlock()
        return (payload, response)
    }
}

enum HTTPResponses {
    static let ok = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!

    static func status(_ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

enum TestSources {
    static func rss(named name: String = "Feed") -> NewsSource {
        NewsSource(name: name, type: .rss, endpointURL: URL(string: "https://example.com/rss")!)
    }

    static func atom(named name: String = "Atom") -> NewsSource {
        NewsSource(name: name, type: .atom, endpointURL: URL(string: "https://example.com/atom")!)
    }

    static func json(named name: String = "API") -> NewsSource {
        NewsSource(name: name, type: .jsonAPI, endpointURL: URL(string: "https://example.com/api")!)
    }
}
