import Foundation

/// Applies the user-selected `AppSettings.language` by overriding the
/// `AppleLanguages` user default before any localization lookup happens.
///
/// This is invoked from the `@main` app struct's initializer, which runs
/// before SwiftUI renders its first view and before `NSBundle` resolves any
/// localized strings, so the override takes effect on the current launch.
enum LanguagePreference {
    private static let appleLanguagesKey = "AppleLanguages"
    private static let settingsKey = "app_settings_v1"

    static func applyAtStartup(defaults: UserDefaults = .standard) {
        let language = storedLanguage(in: defaults)
        apply(language: language, to: defaults)
    }

    static func apply(language: AppLanguage, to defaults: UserDefaults = .standard) {
        if let identifier = language.localeIdentifier {
            defaults.set([identifier], forKey: appleLanguagesKey)
        } else {
            defaults.removeObject(forKey: appleLanguagesKey)
        }
    }

    private static func storedLanguage(in defaults: UserDefaults) -> AppLanguage {
        guard
            let data = defaults.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .system
        }
        return settings.language
    }
}
