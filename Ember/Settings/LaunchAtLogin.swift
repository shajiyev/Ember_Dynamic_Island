import ServiceManagement

/// The only login-item code: whether Ember starts at login, through macOS's login-item
/// service. The user can also change it in System Settings → General → Login Items.
enum LaunchAtLogin {
    enum Status {
        case on
        case off
        /// Registered, but macOS waits for the user to allow it in Login Items.
        case needsApproval
    }

    static var status: Status {
        switch SMAppService.mainApp.status {
        case .enabled: return .on
        case .requiresApproval: return .needsApproval
        default: return .off
        }
    }

    /// Turns starting at login on or off. If macOS refuses, `status` still tells the truth,
    /// and the switch shows it.
    static func turn(on: Bool) {
        if on {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    static func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
