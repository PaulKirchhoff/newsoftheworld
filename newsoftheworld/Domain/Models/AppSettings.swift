import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var appearance: AppearanceMode
    var autoShowTickerOnLaunch: Bool
    var tickerSpeed: Double
    var tickerFontSize: Double
    var tickerPanelWidth: Double
    var language: AppLanguage

    nonisolated static let `default` = AppSettings(
        appearance: .system,
        autoShowTickerOnLaunch: false,
        tickerSpeed: 60,
        tickerFontSize: 13,
        tickerPanelWidth: 520,
        language: .system
    )

    nonisolated init(
        appearance: AppearanceMode,
        autoShowTickerOnLaunch: Bool,
        tickerSpeed: Double,
        tickerFontSize: Double,
        tickerPanelWidth: Double,
        language: AppLanguage
    ) {
        self.appearance = appearance
        self.autoShowTickerOnLaunch = autoShowTickerOnLaunch
        self.tickerSpeed = tickerSpeed
        self.tickerFontSize = tickerFontSize
        self.tickerPanelWidth = tickerPanelWidth
        self.language = language
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings.default
        self.appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? d.appearance
        self.autoShowTickerOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .autoShowTickerOnLaunch) ?? d.autoShowTickerOnLaunch
        self.tickerSpeed = try container.decodeIfPresent(Double.self, forKey: .tickerSpeed) ?? d.tickerSpeed
        self.tickerFontSize = try container.decodeIfPresent(Double.self, forKey: .tickerFontSize) ?? d.tickerFontSize
        self.tickerPanelWidth = try container.decodeIfPresent(Double.self, forKey: .tickerPanelWidth) ?? d.tickerPanelWidth
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? d.language
    }
}
