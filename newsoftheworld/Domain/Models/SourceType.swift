import Foundation

enum SourceType: String, Codable, CaseIterable, Sendable {
    case rss
    case atom
    case jsonAPI = "json_api"

    var localizedName: String {
        switch self {
        case .rss:     "RSS"
        case .atom:    "Atom"
        case .jsonAPI: "JSON-API"
        }
    }
}
