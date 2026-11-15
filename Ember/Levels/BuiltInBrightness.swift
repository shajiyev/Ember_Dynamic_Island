import CoreGraphics
import Foundation

/// The built-in screen's brightness, through Apple's private DisplayServices framework. The
/// only private-framework code. It is loaded at run time, so if it is missing, brightness
/// keys simply stay with macOS. It works only outside the App Sandbox (docs/decisions.md,
/// 2026-11-14).
final class BuiltInBrightness: BrightnessControl {
    private typealias GetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private let getFunction: GetBrightness?
    private let setFunction: SetBrightness?

    init() {
        let framework = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
        getFunction = framework.flatMap { dlsym($0, "DisplayServicesGetBrightness") }
            .map { unsafeBitCast($0, to: GetBrightness.self) }
        setFunction = framework.flatMap { dlsym($0, "DisplayServicesSetBrightness") }
            .map { unsafeBitCast($0, to: SetBrightness.self) }
    }

    func brightness() -> Double? {
        guard let getFunction, let display = Self.builtInDisplay() else { return nil }
        var level: Float = 0
        guard getFunction(display, &level) == 0 else { return nil }
        return Double(level)
    }

    func setBrightness(_ level: Double) {
        guard let setFunction, let display = Self.builtInDisplay() else { return }
        _ = setFunction(display, Float(level))
    }

    var isPointedAt: Bool {
        // Global display coordinates, which `CGGetDisplaysWithPoint` expects.
        guard let pointer = CGEvent(source: nil)?.location, let builtIn = Self.builtInDisplay() else { return false }
        var display: CGDirectDisplayID = 0
        var count: UInt32 = 0
        guard CGGetDisplaysWithPoint(pointer, 1, &display, &count) == .success, count == 1 else { return false }
        return display == builtIn
    }

    /// The built-in screen while it is on. Never "the main display", which may be an
    /// external monitor (DisplayServices fails for those).
    private static func builtInDisplay() -> CGDirectDisplayID? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(displays.count), &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 && CGDisplayIsAsleep($0) == 0 }
    }
}
