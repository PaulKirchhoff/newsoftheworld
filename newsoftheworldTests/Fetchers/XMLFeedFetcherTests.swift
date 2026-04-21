import Foundation
import Testing
@testable import newsoftheworld

@MainActor
struct XMLFeedFetcherTests {
    @Test
    func parsesRSS2Feed() async throws {
        let client = FakeHTTPClient(data: Fixtures.rss2Feed, response: HTTPResponses.ok)
        let fetcher = XMLFeedFetcher(httpClient: client)
        let source = TestSources.rss()

        let items = try await fetcher.fetch(source: source, apiKey: nil)

        #expect(items.count == 2)
        let first = try #require(items.first)
        #expect(first.title == "Item 1")
        #expect(first.url?.absoluteString == "https://example.com/1")
        #expect(first.summary == "First item description")
        #expect(first.publishedAt != nil)
        #expect(first.sourceId == source.id)
    }

    @Test
    func parsesAtomFeedWithLinkHrefAttribute() async throws {
        let client = FakeHTTPClient(data: Fixtures.atomFeed, response: HTTPResponses.ok)
        let fetcher = XMLFeedFetcher(httpClient: client)

        let items = try await fetcher.fetch(source: TestSources.atom(), apiKey: nil)

        #expect(items.count == 2)
        let first = try #require(items.first)
        #expect(first.title == "Entry A")
        #expect(first.url?.absoluteString == "https://example.com/a")
        #expect(first.summary == "Summary A")
        #expect(first.publishedAt != nil)
    }

    @Test
    func parsesAtomEntryWithoutExplicitRel() async throws {
        let client = FakeHTTPClient(data: Fixtures.atomFeed, response: HTTPResponses.ok)
        let fetcher = XMLFeedFetcher(httpClient: client)

        let items = try await fetcher.fetch(source: TestSources.atom(), apiKey: nil)

        let second = try #require(items.dropFirst().first)
        #expect(second.title == "Entry B")
        #expect(second.url?.absoluteString == "https://example.com/b")
    }

    @Test
    func throwsOnMalformedXML() async {
        let client = FakeHTTPClient(data: Fixtures.malformedXML, response: HTTPResponses.ok)
        let fetcher = XMLFeedFetcher(httpClient: client)

        await #expect(throws: (any Error).self) {
            _ = try await fetcher.fetch(source: TestSources.rss(), apiKey: nil)
        }
    }

    @Test
    func throwsOnHTTPError() async {
        let client = FakeHTTPClient(data: Data(), response: HTTPResponses.status(500))
        let fetcher = XMLFeedFetcher(httpClient: client)

        await #expect(throws: NewsFetcherError.self) {
            _ = try await fetcher.fetch(source: TestSources.rss(), apiKey: nil)
        }
    }

    @Test
    func sendsBearerTokenWhenAPIKeyProvided() async throws {
        let client = FakeHTTPClient(data: Fixtures.rss2Feed, response: HTTPResponses.ok)
        let fetcher = XMLFeedFetcher(httpClient: client)

        _ = try await fetcher.fetch(source: TestSources.rss(), apiKey: "abc123")

        let auth = client.lastRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(auth == "Bearer abc123")
    }
}
