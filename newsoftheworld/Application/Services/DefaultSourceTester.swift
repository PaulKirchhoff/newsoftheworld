import Foundation

nonisolated
struct DefaultSourceTester: SourceTester {
    let resolver: FetcherResolver

    func test(name: String, type: SourceType, url: URL, apiKey: String?) async -> SourceTestResult {
        guard let fetcher = resolver.fetcher(for: type) else {
            return .failure("Kein Fetcher für Typ \(type.localizedName)")
        }
        let probe = NewsSource(name: name, type: type, endpointURL: url)
        do {
            let items = try await fetcher.fetch(source: probe, apiKey: apiKey)
            return .success(itemCount: items.count)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failure(message)
        }
    }
}
