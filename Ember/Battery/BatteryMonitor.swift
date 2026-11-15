import CoreFoundation
import IOKit.ps
import Observation

/// Watches the internal battery. Publishes the current reading for the panel and hands
/// each alert, as a live activity, to `onAlert`.
@Observable
final class BatteryMonitor {
    /// Nil before `start()`, and on a Mac without a battery.
    private(set) var reading: BatteryReading?
    /// Called with the live activity for each battery alert.
    @ObservationIgnored var onAlert: ((LiveActivity) -> Void)?
    @ObservationIgnored private var rules = BatteryAlertRules()
    /// IOKit's change notices, while listening.
    @ObservationIgnored private var source: CFRunLoopSource?

    /// Takes a first reading and starts listening for power-source changes. IOKit keeps
    /// an unretained pointer to the monitor, so the monitor must live as long as the app.
    func start() {
        guard source == nil else { return }   // already listening
        let context = Unmanaged.passUnretained(self).toOpaque()
        source = IOPSNotificationCreateRunLoopSource(powerSourcesChanged, context)?.takeRetainedValue()
        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        refresh()
    }

    /// Stops listening for power-source changes and forgets the reading.
    func stop() {
        guard let source else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        self.source = nil
        reading = nil
        rules = BatteryAlertRules()   // a later start must not compare with a reading from before the stop
    }

    fileprivate func refresh() {
        let newReading = BatteryReading.current()
        guard newReading != reading else { return }   // IOKit also reports changes we ignore
        reading = newReading
        guard let newReading, let alert = rules.alert(for: newReading) else { return }
        onAlert?(alert.liveActivity(for: newReading))
    }
}

/// Called by IOKit on the main run loop whenever a power source changes.
private nonisolated func powerSourcesChanged(_ context: UnsafeMutableRawPointer?) {
    // The pointer is passed as a number so it can cross into the main-actor closure.
    guard let address = context.map(UInt.init(bitPattern:)) else { return }
    MainActor.assumeIsolated {
        guard let context = UnsafeMutableRawPointer(bitPattern: address) else { return }
        Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
    }
}
