import Foundation

protocol SettingsRepository: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}
