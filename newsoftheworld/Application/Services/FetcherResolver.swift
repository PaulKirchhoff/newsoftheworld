import Foundation

struct FetcherResolver: Sendable {
    private let fetchers: [SourceType: any NewsFetcher]

    init(fetchers: [SourceType: any NewsFetcher]) {
        self.fetchers = fetchers
    }

    func fetcher(for type: SourceType) -> (any NewsFetcher)? {
        fetchers[type]
    }
}
