import Foundation

enum LaunchAtLoginState: Sendable, Equatable {
    case enabled
    case disabled
    case requiresApproval
    case notAvailable
}

protocol LaunchAtLoginService: Sendable {
    var state: LaunchAtLoginState { get }
    func setEnabled(_ enabled: Bool) throws
}
