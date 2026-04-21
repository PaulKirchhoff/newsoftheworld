import Foundation

nonisolated
final class JSONFeedFetcher: NewsFetcher {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch(source: NewsSource, apiKey: String?) async throws -> [NewsItem] {
        var request = URLRequest(url: source.endpointURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await httpClient.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NewsFetcherError.httpStatus(http.statusCode)
        }

        let rawItems = try extractItems(from: data)
        return rawItems.compactMap { map($0, source: source) }
    }

    private func extractItems(from data: Data) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: data)

        if let array = object as? [[String: Any]] {
            return array
        }

        guard let dict = object as? [String: Any] else {
            throw NewsFetcherError.unsupportedPayloadShape
        }

        for key in ["items", "articles", "results", "data", "entries", "posts", "news"] {
            if let array = dict[key] as? [[String: Any]] {
                return array
            }
        }
        throw NewsFetcherError.unsupportedPayloadShape
    }

    private func map(_ item: [String: Any], source: NewsSource) -> NewsItem? {
        let title = firstString(item, keys: ["title", "headline", "name"])
        guard let title, !title.isEmpty else { return nil }

        let urlString = firstString(item, keys: ["url", "link", "canonical_url", "permalink", "detailsweb", "shareURL"])
        let url = urlString.flatMap { URL(string: $0) }
        let dateString = firstString(item, keys: ["publishedAt", "published_at", "pubDate", "published", "date", "updated"])
        let publishedAt = dateString.flatMap { FeedDateParser.parse($0) }
        let summary = firstString(item, keys: ["summary", "description", "excerpt", "firstSentence"])
        let author = firstString(item, keys: ["author", "byline", "creator"])
        let category = firstString(item, keys: ["topline", "kicker", "category"])
        let rawID = firstString(item, keys: ["id", "guid", "uuid", "externalId", "sophoraId"]) ?? urlString ?? title

        return NewsItem(
            id: "\(source.id.uuidString)-\(rawID)",
            sourceId: source.id,
            sourceName: source.name,
            title: title,
            url: url,
            publishedAt: publishedAt,
            summary: summary,
            category: category,
            author: author
        )
    }

    private func firstString(_ item: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = item[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
