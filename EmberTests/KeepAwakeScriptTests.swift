import Testing
@testable import Ember

struct KeepAwakeScriptTests {
    @Test func startingTurnsSleepOffAndLeavesAWatcherThatTurnsItBackOn() {
        let script = KeepAwakeScript.start(deadline: 1_800_000_000, emberPID: 4242)
        #expect(script.hasPrefix("pmset -a disablesleep 1"))
        #expect(script.contains("end=1800000000"))        // the chosen time
        #expect(script.contains("kill -0 4242"))            // Ember quit or crashed
        #expect(script.contains("-le 10"))                  // 10% on battery
        #expect(script.contains("Battery Power"))
        #expect(script.contains("echo $$ > \(KeepAwakeScript.pidFile)"))
        #expect(script.contains("pmset -a disablesleep 0"))
        #expect(script.hasSuffix("> /dev/null 2>&1 &"))     // returns at once
        #expect(script.filter { $0 == "'" }.count == 2)   // the watcher is one single-quoted text
    }

    @Test func untilStoppedHasNoDeadline() {
        #expect(KeepAwakeScript.start(deadline: nil, emberPID: 1).contains("end=0"))
    }

    @Test func stoppingEndsTheWatcherAndTurnsSleepBackOn() {
        let script = KeepAwakeScript.stop()
        #expect(script.contains("kill $(cat \(KeepAwakeScript.pidFile))"))
        #expect(script.hasSuffix("pmset -a disablesleep 0"))
    }

    @Test func theShellRunsWithAdminRightsAndItsQuotesEscaped() {
        #expect(KeepAwakeScript.appleScript(running: #"echo "a\b""#)
                == #"do shell script "echo \"a\\b\"" with administrator privileges"#)
    }

    @Test func sleepDisabledIsReadFromPmset() {
        #expect(KeepAwakeScript.isSleepDisabled(pmsetOutput: "System-wide power settings:\n SleepDisabled\t\t1\n"))
        #expect(!KeepAwakeScript.isSleepDisabled(pmsetOutput: " SleepDisabled\t\t0\n"))
        #expect(!KeepAwakeScript.isSleepDisabled(pmsetOutput: "Currently in use:\n sleep 1\n"))
    }

    @Test func withoutAPasswordThePmsetCallsGoThroughSudoAndTheWatcherRunsAsTheUser() {
        let script = KeepAwakeScript.start(deadline: 1, emberPID: 7, pmset: KeepAwakeScript.sudoPmset, pidFile: "/tmp/e.pid")
        #expect(script.hasPrefix("sudo -n /usr/bin/pmset -a disablesleep 1 || exit 1; "))   // no sleep change, no watcher
        #expect(script.contains("sudo -n /usr/bin/pmset -a disablesleep 0"))
        #expect(script.contains("echo $$ > /tmp/e.pid"))
        let stop = KeepAwakeScript.stop(pmset: KeepAwakeScript.sudoPmset, pidFile: "/tmp/e.pid")
        #expect(stop.contains("kill $(cat /tmp/e.pid)") && stop.hasSuffix("sudo -n /usr/bin/pmset -a disablesleep 0"))
    }

    @Test func theRuleAllowsOnlyTheTwoSleepCommandsForThisUser() {
        #expect(KeepAwakeScript.sudoersRule(user: "alex")
                == "alex ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0")
        // A name sudoers could misread falls back to the Mac's admins.
        #expect(KeepAwakeScript.sudoersRule(user: "a b,c").hasPrefix("%admin ALL="))
    }

    @Test func theRuleIsCheckedBeforeItIsInstalledAndCanBeRemoved() {
        let install = KeepAwakeScript.installRule(user: "alex")
        #expect(install.contains("/usr/sbin/visudo -cf \"$t\" && /usr/bin/install -m 0440 -o root -g wheel \"$t\" \(KeepAwakeScript.ruleFile)"))
        #expect(install.contains("alex ALL=(root) NOPASSWD:"))
        #expect(KeepAwakeScript.removeRule == "rm -f \(KeepAwakeScript.ruleFile)")
    }
}
