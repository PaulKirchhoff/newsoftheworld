import Foundation

protocol NewsFetcher: Sendable {
    func fetch(source: NewsSource, apiKey: String?) async throws -> [NewsItem]
}
