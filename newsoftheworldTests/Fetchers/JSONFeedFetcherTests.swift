import Foundation
import Testing
@testable import newsoftheworld

@MainActor
struct JSONFeedFetcherTests {
    @Test
    func mapsSimpleItemsShape() async throws {
        let client = FakeHTTPClient(data: Fixtures.simpleItemsJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)
        let source = TestSources.json()

        let items = try await fetcher.fetch(source: source, apiKey: nil)

        #expect(items.count == 2)
        #expect(items[0].title == "Hello")
        #expect(items[0].url?.absoluteString == "https://example.com/a")
        #expect(items[0].summary == "Greeting")
        #expect(items[0].publishedAt != nil)
        #expect(items[0].sourceId == source.id)
    }

    @Test
    func mapsRootArrayShape() async throws {
        let client = FakeHTTPClient(data: Fixtures.rootArrayJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        let items = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)

        #expect(items.count == 2)
        #expect(items[0].title == "Alpha")
        #expect(items[1].title == "Beta")
    }

    @Test
    func mapsTagesschauShapeWithToplineAndShareURL() async throws {
        let client = FakeHTTPClient(data: Fixtures.tagesschauLikeJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        let items = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)

        #expect(items.count == 2)
        let first = try #require(items.first)
        #expect(first.title == "Prinzip Hoffnung an der Börse")
        #expect(first.category == "Steigender DAX")
        #expect(first.summary == "An der Börse ist mehr Zuversicht aufgekommen.")
        #expect(first.url?.absoluteString == "https://www.tagesschau.de/wirtschaft/finanzen/story-1.html")
        #expect(first.publishedAt != nil)
    }

    @Test
    func throwsOnUnsupportedShape() async {
        let client = FakeHTTPClient(data: Fixtures.unsupportedJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        await #expect(throws: NewsFetcherError.self) {
            _ = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)
        }
    }

    @Test
    func throwsOnMalformedJSON() async {
        let client = FakeHTTPClient(data: Fixtures.malformedJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        await #expect(throws: (any Error).self) {
            _ = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)
        }
    }

    @Test
    func throwsOnHTTPError() async {
        let client = FakeHTTPClient(data: Data(), response: HTTPResponses.status(404))
        let fetcher = JSONFeedFetcher(httpClient: client)

        await #expect(throws: NewsFetcherError.self) {
            _ = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)
        }
    }

    @Test
    func sendsBearerTokenWhenAPIKeyProvided() async throws {
        let client = FakeHTTPClient(data: Fixtures.simpleItemsJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        _ = try await fetcher.fetch(source: TestSources.json(), apiKey: "secret-token")

        let auth = client.lastRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(auth == "Bearer secret-token")
    }

    @Test
    func omitsAuthorizationWhenNoAPIKey() async throws {
        let client = FakeHTTPClient(data: Fixtures.simpleItemsJSON, response: HTTPResponses.ok)
        let fetcher = JSONFeedFetcher(httpClient: client)

        _ = try await fetcher.fetch(source: TestSources.json(), apiKey: nil)

        #expect(client.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }
}
