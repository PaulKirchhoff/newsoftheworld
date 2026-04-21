import Foundation

nonisolated
final class XMLFeedFetcher: NewsFetcher {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch(source: NewsSource, apiKey: String?) async throws -> [NewsItem] {
        var request = URLRequest(url: source.endpointURL)
        request.setValue(
            "application/rss+xml, application/atom+xml, application/xml, text/xml",
            forHTTPHeaderField: "Accept"
        )
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await httpClient.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NewsFetcherError.httpStatus(http.statusCode)
        }

        let delegate = FeedXMLDelegate(source: source)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw NewsFetcherError.parseFailure(parser.parserError?.localizedDescription ?? "unknown")
        }
        return delegate.items
    }
}

private final class FeedXMLDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    let source: NewsSource
    var items: [NewsItem] = []

    private var currentPath: [String] = []
    private var inEntry = false
    private var title = ""
    private var linkText = ""
    private var atomLinkHref = ""
    private var dateString = ""
    private var summaryText = ""
    private var authorText = ""
    private var guidText = ""

    init(source: NewsSource) {
        self.source = source
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = elementName.lowercased()
        currentPath.append(name)

        switch name {
        case "item", "entry":
            inEntry = true
            title = ""
            linkText = ""
            atomLinkHref = ""
            dateString = ""
            summaryText = ""
            authorText = ""
            guidText = ""
        case "link" where inEntry:
            if let href = attributeDict["href"] {
                let rel = attributeDict["rel"] ?? "alternate"
                if rel == "alternate" {
                    atomLinkHref = href
                }
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inEntry, let current = currentPath.last else { return }

        switch current {
        case "title":       title += string
        case "link":        if atomLinkHref.isEmpty { linkText += string }
        case "pubdate", "published", "updated", "dc:date":
            dateString += string
        case "description", "summary", "content":
            summaryText += string
        case "author", "dc:creator":
            authorText += string
        case "guid", "id":
            guidText += string
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = elementName.lowercased()
        defer { if currentPath.last == name { currentPath.removeLast() } }

        guard name == "item" || name == "entry" else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            let urlString = atomLinkHref.isEmpty
                ? linkText.trimmingCharacters(in: .whitespacesAndNewlines)
                : atomLinkHref
            let url = URL(string: urlString)
            let date = FeedDateParser.parse(dateString)
            let cleanedGUID = guidText.trimmingCharacters(in: .whitespacesAndNewlines)
            let identity = !cleanedGUID.isEmpty
                ? cleanedGUID
                : (urlString.isEmpty ? trimmedTitle : urlString)
            let author = authorText.trimmingCharacters(in: .whitespacesAndNewlines)
            let summary = summaryText.trimmingCharacters(in: .whitespacesAndNewlines)

            items.append(NewsItem(
                id: "\(source.id.uuidString)-\(identity)",
                sourceId: source.id,
                sourceName: source.name,
                title: trimmedTitle,
                url: url,
                publishedAt: date,
                summary: summary.isEmpty ? nil : summary,
                author: author.isEmpty ? nil : author
            ))
        }
        inEntry = false
    }
}
