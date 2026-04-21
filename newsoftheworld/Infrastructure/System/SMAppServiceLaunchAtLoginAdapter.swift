import Foundation
import ServiceManagement
import os

nonisolated
final class SMAppServiceLaunchAtLoginAdapter: LaunchAtLoginService {
    var state: LaunchAtLoginState {
        switch SMAppService.mainApp.status {
        case .enabled:          return .enabled
        case .requiresApproval: return .requiresApproval
        case .notRegistered:    return .disabled
        case .notFound:         return .notAvailable
        @unknown default:       return .notAvailable
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            AppLog.launch.error("SMAppService \(enabled ? "register" : "unregister") failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
