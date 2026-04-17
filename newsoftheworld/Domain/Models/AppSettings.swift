import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var appearance: AppearanceMode
    var autoShowTickerOnLaunch: Bool
    var tickerSpeed: Double

    static let `default` = AppSettings(
        appearance: .system,
        autoShowTickerOnLaunch: false,
        tickerSpeed: 60
    )
}
