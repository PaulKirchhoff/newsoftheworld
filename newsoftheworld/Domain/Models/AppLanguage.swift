import Foundation

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system
    case german = "de"
    case english = "en"
    case french = "fr"
    case spanish = "es"

    /// Language name written in its own language, so the user can recognize
    /// the option even when the app is currently displayed in another locale.
    nonisolated var displayName: String {
        switch self {
        case .system:  "—"
        case .german:  "Deutsch"
        case .english: "English"
        case .french:  "Français"
        case .spanish: "Español"
        }
    }

    /// Locale identifier applied to the AppleLanguages user default. `nil`
    /// means "respect system language" (no override).
    nonisolated var localeIdentifier: String? {
        switch self {
        case .system: nil
        case .german, .english, .french, .spanish: rawValue
        }
    }
}
