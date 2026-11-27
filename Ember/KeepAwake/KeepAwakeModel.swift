import AppKit
import IOKit.pwr_mgt
import Observation

/// Keep awake (#18): one session at a time, for a number of minutes or until stopped. The
/// lid-open part is a power assertion that stops idle sleep; the lid-closed part, when asked,
/// runs `KeepAwakeScript`, whose watcher turns sleep back on by itself: through sudo with no
/// password once the rule is installed (Allow Without Password), otherwise as root through
/// macOS's password dialog.
@Observable
final class KeepAwakeModel {
    struct Session: Equatable {
        /// Nil keeps it until Stop.
        let endsAt: Date?
        /// The chosen time, for the tab's ring and lit button; nil until stopped.
        let minutes: Int?
        var lidClosed: Bool
    }

    private(set) var session: Session?
    /// Seconds left, brought up to date every few seconds for the menus; nil until stopped.
    private(set) var secondsLeft: TimeInterval?
    /// The sudoers rule is installed: lid-closed starts and stops ask no password.
    private(set) var allowsWithoutPassword = FileManager.default.fileExists(atPath: KeepAwakeScript.ruleFile)

    @ObservationIgnored private var assertion: IOPMAssertionID?
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private let defaults: UserDefaults
    /// Set while a lid-closed session runs, so a launch after a restart can find
    /// `disablesleep` left on.
    private static let lidClosedRunningKey = "keepAwakeLidClosedRunning"
    /// The watcher's process number when it runs as the user (through sudo).
    private static let userPidFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("ember-keep-awake.pid")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Starts keeping awake, replacing a running session. With `lidClosed`, macOS asks for the
    /// admin password; cancelling it starts nothing and leaves a running session as it was.
    func start(minutes: Int?, lidClosed: Bool) {
        let endsAt = minutes.map { Date().addingTimeInterval(TimeInterval($0 * 60)) }
        let wasLidClosed = session?.lidClosed == true
        if lidClosed {
            let deadline = endsAt.map { Int($0.timeIntervalSince1970) }
            let ran = runLidClosed { pmset, pidFile in
                let start = KeepAwakeScript.start(deadline: deadline, emberPID: ProcessInfo.processInfo.processIdentifier,
                                                  pmset: pmset, pidFile: pidFile)
                return wasLidClosed ? KeepAwakeScript.stop(pmset: pmset, pidFile: pidFile) + "; " + start : start
            }
            guard ran else { return }
        } else if wasLidClosed {
            guard runLidClosed(KeepAwakeScript.stop) else { return }
        }
        defaults.set(lidClosed, forKey: Self.lidClosedRunningKey)
        holdAssertion()
        session = Session(endsAt: endsAt, minutes: minutes, lidClosed: lidClosed)
        startTicking()
    }

    /// Stops keeping awake. A lid-closed session asks for the password to turn sleep back on;
    /// cancelling it leaves the session running.
    func stop() {
        guard let session else { return }
        if session.lidClosed {
            guard runLidClosed(KeepAwakeScript.stop) else { return }
        }
        end()
    }

    /// Ember is quitting: with the rule, sleep comes back at once; otherwise the watcher
    /// brings it back within 20 s.
    func endOnQuit() {
        guard session?.lidClosed == true, allowsWithoutPassword else { return }
        _ = UserShell.run(KeepAwakeScript.stop(pmset: KeepAwakeScript.sudoPmset, pidFile: Self.userPidFile))
    }

    /// Settings → Keep Awake → Allow Without Password: installs the sudoers rule (one password).
    func allowWithoutPassword() {
        _ = AdminShell.run(KeepAwakeScript.installRule(user: NSUserName()))
        allowsWithoutPassword = FileManager.default.fileExists(atPath: KeepAwakeScript.ruleFile)
    }

    /// Removes the rule (one password). A lid-closed session running through sudo is stopped
    /// in the same step, as its watcher could no longer turn sleep back on.
    func removeRule() {
        var script = KeepAwakeScript.removeRule
        if session?.lidClosed == true {
            script = KeepAwakeScript.stop(pmset: KeepAwakeScript.rootPmset, pidFile: Self.userPidFile) + "; "
                + KeepAwakeScript.stop() + "; " + script
        }
        guard AdminShell.run(script) else { return }
        allowsWithoutPassword = FileManager.default.fileExists(atPath: KeepAwakeScript.ruleFile)
        if session?.lidClosed == true { session?.lidClosed = false }
    }

    /// Runs a lid-closed script through sudo when the rule allows it, falling back to the
    /// password dialog. False when it did not run (the password was cancelled).
    private func runLidClosed(_ script: (_ pmset: String, _ pidFile: String) -> String) -> Bool {
        if allowsWithoutPassword, UserShell.run(script(KeepAwakeScript.sudoPmset, Self.userPidFile)) { return true }
        return AdminShell.run(script(KeepAwakeScript.rootPmset, KeepAwakeScript.pidFile))
    }

    /// After a restart in the middle of a lid-closed session, sleep stays off: the watcher is
    /// gone. Offers to turn it back on. Called once at launch.
    func checkAfterRestart() {
        guard defaults.bool(forKey: Self.lidClosedRunningKey) else { return }
        defaults.removeObject(forKey: Self.lidClosedRunningKey)
        // A watcher still running (Ember was quit moments ago) turns sleep back on itself.
        let watcherRuns = [KeepAwakeScript.pidFile, Self.userPidFile].contains { FileManager.default.fileExists(atPath: $0) }
        guard Self.isSleepDisabled(), !watcherRuns else { return }
        if allowsWithoutPassword, UserShell.run(KeepAwakeScript.stop(pmset: KeepAwakeScript.sudoPmset, pidFile: Self.userPidFile)) {
            return
        }
        let alert = NSAlert()
        alert.messageText = "Your Mac was kept awake with the lid closed when it restarted."
        alert.informativeText = "Sleep is still switched off. Switch it back on? macOS asks for your password."
        alert.addButton(withTitle: "Switch Sleep Back On")
        alert.addButton(withTitle: "Leave It Off")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            _ = AdminShell.run(KeepAwakeScript.stop())
        }
    }

    private func end() {
        ticker?.cancel()
        ticker = nil
        releaseAssertion()
        defaults.removeObject(forKey: Self.lidClosedRunningKey)
        session = nil
        secondsLeft = nil
    }

    /// Every 15 s: the time left for the menus, the end of the session, and whether the
    /// watcher turned sleep back on (at 10% on battery), which leaves the lid open only.
    private func startTicking() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            var checks = 0
            while let self, !Task.isCancelled, let session = self.session {
                if let endsAt = session.endsAt {
                    let left = endsAt.timeIntervalSinceNow
                    guard left > 0 else { self.end(); return }   // the watcher turns sleep back on itself
                    self.secondsLeft = left
                }
                if session.lidClosed, checks % 4 == 0, !Self.isSleepDisabled() {
                    self.session?.lidClosed = false
                    self.defaults.removeObject(forKey: Self.lidClosedRunningKey)
                }
                checks += 1
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    private func holdAssertion() {
        guard assertion == nil else { return }
        var id = IOPMAssertionID(0)
        let made = IOPMAssertionCreateWithName("PreventUserIdleSystemSleep" as CFString,
                                               IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                               "Ember: Keep awake" as CFString, &id)
        if made == kIOReturnSuccess { assertion = id }
    }

    private func releaseAssertion() {
        guard let assertion else { return }
        IOPMAssertionRelease(assertion)
        self.assertion = nil
    }

    /// Reads `pmset -g`; no admin rights needed.
    private static func isSleepDisabled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe
        guard (try? process.run()) != nil else { return false }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return KeepAwakeScript.isSleepDisabled(pmsetOutput: String(decoding: data, as: UTF8.self))
    }
}

/// Runs a shell command as the user, without asking anything.
enum UserShell {
    /// False when it could not start or ended with an error (sudo refused without a password).
    static func run(_ shell: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", shell]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return false }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}

/// Runs a shell command as root after macOS asks for the admin password.
enum AdminShell {
    /// False when the user cancelled the password or the command failed.
    static func run(_ shell: String) -> Bool {
        var error: NSDictionary?
        NSAppleScript(source: KeepAwakeScript.appleScript(running: shell))?.executeAndReturnError(&error)
        return error == nil
    }
}
