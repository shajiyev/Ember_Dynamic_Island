import Testing
@testable import Ember

struct KeyShortcutTests {
    @Test func theStandardShortcutIsControlOptionN() {
        #expect(KeyShortcut.standard == KeyShortcut(keyCode: 45, modifiers: [.control, .option]))
        #expect(KeyShortcut.standard.text == "⌃⌥N")
    }

    @Test func modifiersShowInMacOSsOrder() {
        #expect(KeyShortcut(keyCode: 40, modifiers: [.command, .shift, .option, .control]).text == "⌃⌥⇧⌘K")
        #expect(KeyShortcut(keyCode: 49, modifiers: [.option]).text == "⌥Space")
    }

    @Test func theKeyLabelTypedOnThisKeyboardIsShownWhenKnown() {
        // On a French keyboard, the key in the place of Q types A.
        #expect(KeyShortcut(keyCode: 12, modifiers: [.control], label: "a").text == "⌃A")
    }

    @Test func aShortcutSurvivesBeingSaved() {
        let shortcut = KeyShortcut(keyCode: 12, modifiers: [.control, .command], label: "a")
        let read = KeyShortcut(saved: shortcut.saved)
        #expect(read == shortcut)
        #expect(read?.text == "⌃⌘A")
        #expect(KeyShortcut(saved: "nonsense") == nil)
    }

    @Test func theLabelDoesNotMakeTwoShortcutsDifferent() {
        #expect(KeyShortcut(keyCode: 12, modifiers: [.control], label: "a") == KeyShortcut(keyCode: 12, modifiers: [.control]))
    }
}

struct ShortcutCheckTests {
    private func verdict(_ keyCode: UInt16, _ modifiers: Set<KeyShortcut.Modifier>,
                         system: Set<KeyShortcut> = []) -> ShortcutCheck.Verdict {
        ShortcutCheck.verdict(KeyShortcut(keyCode: keyCode, modifiers: modifiers), systemShortcuts: system)
    }

    @Test func theStandardShortcutIsFine() {
        #expect(ShortcutCheck.verdict(.standard, systemShortcuts: SystemShortcuts.macOSDefaults) == .fine)
        #expect(verdict(40, [.control, .option]) == .fine)
    }

    @Test func aKeyAloneOrWithShiftIsRefused() {
        #expect(verdict(45, []) == .refused(ShortcutCheck.typingReason))
        #expect(verdict(45, [.shift]) == .refused(ShortcutCheck.typingReason))
    }

    @Test func shortcutsEveryAppUsesAreRefused() {
        #expect(verdict(8, [.command]) == .refused(ShortcutCheck.everyAppReason))    // ⌘C
        #expect(verdict(48, [.command]) == .refused(ShortcutCheck.everyAppReason))   // ⌘Tab
    }

    @Test func shortcutsMacOSHasOnAreRefused() {
        let screenshot = KeyShortcut(keyCode: 21, modifiers: [.command, .shift])     // ⌘⇧4
        #expect(ShortcutCheck.verdict(screenshot, systemShortcuts: [screenshot]) == .refused(ShortcutCheck.macOSReason))
    }

    @Test func shortcutsPopularAppsUseAreNotRecommended() {
        #expect(verdict(49, [.option]) == .notRecommended(ShortcutCheck.popularReason))   // ⌥Space
    }

    @Test func anyOtherShortcutWithCommandIsNotRecommended() {
        #expect(verdict(40, [.command, .shift]) == .notRecommended(ShortcutCheck.commandReason))   // ⌘⇧K
    }
}

struct SystemShortcutsTests {
    @Test func macOSsDefaultsIncludeSpotlightAndScreenshots() {
        let defaults = SystemShortcuts.macOSDefaults
        #expect(defaults.contains(KeyShortcut(keyCode: 49, modifiers: [.command])))          // Spotlight
        #expect(defaults.contains(KeyShortcut(keyCode: 21, modifiers: [.command, .shift])))  // ⌘⇧4
        #expect(defaults.contains(KeyShortcut(keyCode: 49, modifiers: [.control, .option]))) // next language
    }

    @Test func aShortcutSwitchedOffOnThisMacIsLeftOut() {
        let saved: [String: Any] = ["64": ["enabled": false]]   // Spotlight off
        #expect(!SystemShortcuts.effective(saved).contains(KeyShortcut(keyCode: 49, modifiers: [.command])))
    }

    @Test func aShortcutMovedToOtherKeysIsReadFromThisMac() {
        // Spotlight moved to ⌃⌥⌘S: the masks are shift 0x20000, control 0x40000, option
        // 0x80000, command 0x100000; others (such as the function key's) are ignored.
        let saved: [String: Any] = ["64": ["enabled": true,
                                           "value": ["parameters": [115, 1, 0x40000 | 0x80000 | 0x100000 | 0x800000]]]]
        let effective = SystemShortcuts.effective(saved)
        #expect(effective.contains(KeyShortcut(keyCode: 1, modifiers: [.control, .option, .command])))
        #expect(!effective.contains(KeyShortcut(keyCode: 49, modifiers: [.command])))
    }

    @Test func aShortcutSwitchedOnThatHasNoKeysAddsNothing() {
        let saved: [String: Any] = ["164": ["enabled": true, "value": ["parameters": [65535, 65535, 0]]]]
        #expect(SystemShortcuts.effective(saved) == SystemShortcuts.macOSDefaults)
    }
}
