import Foundation

enum NewsFetcherError: Error, LocalizedError {
    case httpStatus(Int)
    case invalidResponse
    case parseFailure(String)
    case unsupportedPayloadShape

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code): "HTTP-Fehler \(code)"
        case .invalidResponse:      "Ungültige Serverantwort"
        case .parseFailure(let m):  "Feed konnte nicht geparst werden: \(m)"
        case .unsupportedPayloadShape: "JSON-Struktur der Quelle wird nicht unterstützt."
        }
    }
}
