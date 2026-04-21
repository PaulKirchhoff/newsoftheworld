import Foundation

struct NewsItem: Identifiable, Hashable, Sendable {
    let id: String
    let sourceId: UUID?
    let sourceName: String?
    let title: String
    let url: URL?
    let publishedAt: Date?
    let summary: String?
    let category: String?
    let author: String?

    nonisolated init(
        id: String,
        sourceId: UUID? = nil,
        sourceName: String? = nil,
        title: String,
        url: URL? = nil,
        publishedAt: Date? = nil,
        summary: String? = nil,
        category: String? = nil,
        author: String? = nil
    ) {
        self.id = id
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.title = title
        self.url = url
        self.publishedAt = publishedAt
        self.summary = summary
        self.category = category
        self.author = author
    }
}
