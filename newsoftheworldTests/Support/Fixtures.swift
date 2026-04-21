import Foundation

enum Fixtures {
    // MARK: - JSON

    static let simpleItemsJSON = Data("""
    {
      "items": [
        {"title": "Hello", "url": "https://example.com/a", "publishedAt": "2024-01-15T12:00:00Z", "summary": "Greeting"},
        {"title": "World", "url": "https://example.com/b", "publishedAt": "2024-01-14T12:00:00Z"}
      ]
    }
    """.utf8)

    static let rootArrayJSON = Data("""
    [
      {"title": "Alpha", "link": "https://example.com/a"},
      {"title": "Beta", "link": "https://example.com/b"}
    ]
    """.utf8)

    static let tagesschauLikeJSON = Data("""
    {
      "news": [
        {
          "sophoraId": "story-1",
          "externalId": "abc-123",
          "title": "Prinzip Hoffnung an der Börse",
          "date": "2026-04-17T14:22:47.479+02:00",
          "topline": "Steigender DAX",
          "firstSentence": "An der Börse ist mehr Zuversicht aufgekommen.",
          "shareURL": "https://www.tagesschau.de/wirtschaft/finanzen/story-1.html"
        },
        {
          "sophoraId": "story-2",
          "externalId": "def-456",
          "title": "Zweite Meldung",
          "date": "2026-04-17T09:00:00.000+02:00",
          "firstSentence": "Ein anderer Vorgang."
        }
      ]
    }
    """.utf8)

    static let unsupportedJSON = Data("""
    {"status": "ok", "meta": {"version": 1}}
    """.utf8)

    static let malformedJSON = Data("not actually json".utf8)

    // MARK: - XML

    static let rss2Feed = Data("""
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
    <channel>
    <title>Test Feed</title>
    <item>
    <title>Item 1</title>
    <link>https://example.com/1</link>
    <pubDate>Mon, 15 Jan 2024 12:00:00 +0000</pubDate>
    <description>First item description</description>
    <guid>item-1</guid>
    </item>
    <item>
    <title>Item 2</title>
    <link>https://example.com/2</link>
    <pubDate>Tue, 16 Jan 2024 08:30:00 +0000</pubDate>
    <guid>item-2</guid>
    </item>
    </channel>
    </rss>
    """.utf8)

    static let atomFeed = Data("""
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
    <title>Atom Test</title>
    <entry>
    <title>Entry A</title>
    <link rel="alternate" href="https://example.com/a"/>
    <updated>2024-02-10T12:00:00Z</updated>
    <summary>Summary A</summary>
    <id>entry-a</id>
    </entry>
    <entry>
    <title>Entry B</title>
    <link href="https://example.com/b"/>
    <updated>2024-02-11T09:00:00Z</updated>
    <id>entry-b</id>
    </entry>
    </feed>
    """.utf8)

    static let malformedXML = Data("<rss><channel><item><title>Unclosed".utf8)
}
