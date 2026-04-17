import Foundation

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var localizedName: String {
        switch self {
        case .system: "System"
        case .light:  "Hell"
        case .dark:   "Dunkel"
        }
    }
}
