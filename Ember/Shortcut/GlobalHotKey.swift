import Carbon.HIToolbox
import Observation

/// A keyboard shortcut that works in every app: the only Carbon `RegisterEventHotKey`
/// code. It needs no permission. macOS can refuse a shortcut another app holds; `isTaken`
/// says so, for the caution in Settings.
@Observable
final class GlobalHotKey {
    /// macOS refused the shortcut last registered.
    private(set) var isTaken = false

    @ObservationIgnored private let action: () -> Void
    @ObservationIgnored private let id: UInt32
    @ObservationIgnored private var hotKey: EventHotKeyRef?
    @ObservationIgnored private var shortcut: KeyShortcut?
    @ObservationIgnored private var isPaused = false

    @ObservationIgnored private static var actions: [UInt32: () -> Void] = [:]
    @ObservationIgnored private static var nextID: UInt32 = 1
    @ObservationIgnored private static var isHandlerInstalled = false
    /// "Embr", so Ember's hot keys are told apart from any other's.
    private static let signature: OSType = 0x456D_6272

    init(action: @escaping () -> Void) {
        self.action = action
        id = Self.nextID
        Self.nextID += 1
        Self.actions[id] = action
        Self.installHandler()
    }

    /// Makes `shortcut` this hot key, or none for nil. Registering the same one again does
    /// nothing.
    func register(_ shortcut: KeyShortcut?) {
        guard shortcut != self.shortcut || (hotKey == nil && !isTaken && shortcut != nil) else { return }
        self.shortcut = shortcut
        apply()
    }

    /// While the user records a new shortcut, the old one must not fire.
    func pause() {
        isPaused = true
        apply()
    }

    func resume() {
        isPaused = false
        apply()
    }

    func unregister() {
        register(nil)
    }

    private func apply() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = nil
        guard let shortcut, !isPaused else {
            if shortcut == nil { isTaken = false }
            return
        }
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(shortcut.keyCode), Self.carbonModifiers(shortcut.modifiers),
                                         EventHotKeyID(signature: Self.signature, id: id),
                                         GetApplicationEventTarget(), 0, &ref)
        hotKey = status == noErr ? ref : nil
        isTaken = status != noErr
    }

    private static func carbonModifiers(_ modifiers: Set<KeyShortcut.Modifier>) -> UInt32 {
        var mask = 0
        if modifiers.contains(.command) { mask |= cmdKey }
        if modifiers.contains(.shift) { mask |= shiftKey }
        if modifiers.contains(.option) { mask |= optionKey }
        if modifiers.contains(.control) { mask |= controlKey }
        return UInt32(mask)
    }

    /// One handler for every Ember hot key; it runs on the main thread.
    private static func installHandler() {
        guard !isHandlerInstalled else { return }
        isHandlerInstalled = true
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            let id = hotKeyID.id
            MainActor.assumeIsolated { GlobalHotKey.actions[id]?() }
            return noErr
        }, 1, &pressed, nil, nil)
    }
}
