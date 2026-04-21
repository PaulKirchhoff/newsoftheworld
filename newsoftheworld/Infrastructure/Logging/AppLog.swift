import Foundation
import os

nonisolated
enum AppLog {
    private static let subsystem = "de.paulkirchhoff.newsoftheworld"

    static let app      = Logger(subsystem: subsystem, category: "app")
    static let refresh  = Logger(subsystem: subsystem, category: "refresh")
    static let fetch    = Logger(subsystem: subsystem, category: "fetch")
    static let sources  = Logger(subsystem: subsystem, category: "sources")
    static let keychain = Logger(subsystem: subsystem, category: "keychain")
    static let launch   = Logger(subsystem: subsystem, category: "launch")
}
