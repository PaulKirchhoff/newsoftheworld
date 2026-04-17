import Foundation

protocol SecretStore: Sendable {
    func setSecret(_ secret: String, for reference: String) throws
    func secret(for reference: String) throws -> String?
    func removeSecret(for reference: String) throws
}
