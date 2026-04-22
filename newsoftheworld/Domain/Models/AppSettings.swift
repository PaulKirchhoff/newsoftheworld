import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var appearance: AppearanceMode
    var autoShowTickerOnLaunch: Bool
    var tickerSpeed: Double
    var tickerFontSize: Double
    /// Ticker panel width expressed as a percentage (0…100) of the
    /// containing screen's width. Concrete pixel width is computed at
    /// render time so changing screens adapts automatically.
    var tickerPanelWidthPercent: Double
    var language: AppLanguage

    nonisolated static let `default` = AppSettings(
        appearance: .system,
        autoShowTickerOnLaunch: false,
        tickerSpeed: 60,
        tickerFontSize: 13,
        tickerPanelWidthPercent: 35,
        language: .system
    )

    nonisolated init(
        appearance: AppearanceMode,
        autoShowTickerOnLaunch: Bool,
        tickerSpeed: Double,
        tickerFontSize: Double,
        tickerPanelWidthPercent: Double,
        language: AppLanguage
    ) {
        self.appearance = appearance
        self.autoShowTickerOnLaunch = autoShowTickerOnLaunch
        self.tickerSpeed = tickerSpeed
        self.tickerFontSize = tickerFontSize
        self.tickerPanelWidthPercent = tickerPanelWidthPercent
        self.language = language
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case tickerPanelWidth
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings.default
        self.appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? d.appearance
        self.autoShowTickerOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .autoShowTickerOnLaunch) ?? d.autoShowTickerOnLaunch
        self.tickerSpeed = try container.decodeIfPresent(Double.self, forKey: .tickerSpeed) ?? d.tickerSpeed
        self.tickerFontSize = try container.decodeIfPresent(Double.self, forKey: .tickerFontSize) ?? d.tickerFontSize
        if let percent = try container.decodeIfPresent(Double.self, forKey: .tickerPanelWidthPercent) {
            self.tickerPanelWidthPercent = percent
        } else if let legacy = try? decoder.container(keyedBy: LegacyCodingKeys.self),
                  let legacyPoints = try legacy.decodeIfPresent(Double.self, forKey: .tickerPanelWidth) {
            // Migrate absolute points to a percentage against a typical
            // 1920-wide screen; the user can re-adjust if they want.
            let migrated = legacyPoints / 1920.0 * 100.0
            self.tickerPanelWidthPercent = min(max(migrated, 10), 100)
        } else {
            self.tickerPanelWidthPercent = d.tickerPanelWidthPercent
        }
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? d.language
    }
}
