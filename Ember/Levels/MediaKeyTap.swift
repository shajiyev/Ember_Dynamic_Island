import AppKit
import ApplicationServices
import CoreGraphics

/// Takes the volume, mute and brightness keys before macOS sees them, so macOS shows no
/// indicator of its own. The only key-capture code. It needs Accessibility; until that is
/// granted it checks again every 2 seconds.
final class MediaKeyTap {
    /// Decides for each press, release or repeat whether Ember takes it (true) or macOS
    /// gets it (false).
    var handler: ((LevelKeyPress) -> Bool)?

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var waitForAccess: Task<Void, Never>?

    /// System-defined events (`NX_SYSDEFINED`, 14), which carry the media keys.
    private static let systemDefinedEvents = CGEventMask(1 << 14)
    private static let accessCheckInterval: Duration = .seconds(2)

    /// Starts taking keys as soon as Ember has Accessibility. `askForAccess` shows macOS's
    /// prompt first if Ember does not have it yet.
    func start(askForAccess: Bool) {
        stop()
        if askForAccess {
            // The value of `kAXTrustedCheckOptionPrompt`, written out because the compiler treats
            // that imported global as shared mutable state.
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        waitForAccess = Task { [weak self] in
            while !Task.isCancelled {
                if AXIsProcessTrusted(), self?.createTap() == true { return }
                try? await Task.sleep(for: Self.accessCheckInterval)
            }
        }
    }

    /// Gives every key back to macOS.
    func stop() {
        waitForAccess?.cancel()
        waitForAccess = nil
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    private func createTap() -> Bool {
        // Where input enters the window server: ahead of every app's session tap (such as
        // BetterDisplay's), whichever started last.
        guard let tap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: Self.systemDefinedEvents,
                                          callback: mediaKeyTapCallback,
                                          userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        self.tap = tap
        self.source = source
        return true
    }

    /// Shift-Option: a quarter step.
    private static func isFine(_ flags: CGEventFlags) -> Bool {
        flags.contains([.maskShift, .maskAlternate])
    }

    /// Command, Control, or Option without Shift: a macOS shortcut, such as Option-Volume
    /// for Sound settings.
    private static func isShortcut(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskCommand) || flags.contains(.maskControl)
            || (flags.contains(.maskAlternate) && !flags.contains(.maskShift))
    }

    /// Whether Ember takes the event. Also switches the tap back on when macOS paused it
    /// (it does that when a tap is slow).
    fileprivate func takes(_ event: CGEvent, type: CGEventType) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined,
              let press = LevelKeyPress(subtype: Int(nsEvent.subtype.rawValue), data1: nsEvent.data1,
                                        isFine: Self.isFine(event.flags), isShortcut: Self.isShortcut(event.flags))
        else { return false }
        return handler?(press) ?? false
    }
}

/// macOS calls this for each system-defined event, on the main run loop, where the tap's
/// source was added.
private nonisolated func mediaKeyTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                                             userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    nonisolated(unsafe) let event = event
    nonisolated(unsafe) let userInfo = userInfo
    let taken = MainActor.assumeIsolated {
        guard let userInfo else { return false }
        return Unmanaged<MediaKeyTap>.fromOpaque(userInfo).takeUnretainedValue().takes(event, type: type)
    }
    return taken ? nil : Unmanaged.passUnretained(event)
}
