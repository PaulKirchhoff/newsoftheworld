import Foundation

protocol NewsSourceRepository: Sendable {
    func load() throws -> [NewsSource]
    func save(_ sources: [NewsSource]) throws
}
