import Foundation

/// The shell that keeps the Mac awake with the lid closed. Only `pmset -a disablesleep`
/// stops macOS sleeping on lid close, and it needs admin rights, so it runs through macOS's
/// own password dialog. Starting also leaves a watcher, run by root, that turns sleep back
/// on by itself: at the deadline, at 10% on battery, or once Ember is no longer running,
/// so sleep never stays off by mistake.
nonisolated enum KeepAwakeScript {
    /// Where the root watcher keeps its process number, so Stop can end it. Cleared at restart.
    static let pidFile = "/var/run/ember-keep-awake.pid"
    /// `pmset` as root (through the password dialog), or through sudo with the rule below.
    static let rootPmset = "pmset"
    static let sudoPmset = "sudo -n /usr/bin/pmset"

    /// Turns sleep off and starts the watcher in the background; stops at once if sleep could
    /// not be turned off. `deadline` is in seconds since 1970; nil keeps it until Stop, the
    /// battery or Ember's end.
    static func start(deadline: Int?, emberPID: Int32, pmset: String = rootPmset, pidFile: String = pidFile) -> String {
        // Every 20 s: the deadline, Ember still running, the battery. Then sleep comes back.
        let watcher = "echo $$ > \(pidFile); end=\(deadline ?? 0); while :; do "
            + "if [ $end -gt 0 ] && [ $(date +%s) -ge $end ]; then break; fi; "
            + "kill -0 \(emberPID) 2>/dev/null || break; "
            + "b=$(pmset -g batt); "
            + "case \"$b\" in *\"Battery Power\"*) p=$(echo \"$b\" | grep -Eo \"[0-9]+%\" | head -n 1 | tr -d %); "
            + "if [ -n \"$p\" ] && [ $p -le 10 ]; then break; fi;; esac; "
            + "sleep 20; done; "
            + "\(pmset) -a disablesleep 0; rm -f \(pidFile)"
        return "\(pmset) -a disablesleep 1 || exit 1; /bin/sh -c '\(watcher)' > /dev/null 2>&1 &"
    }

    /// Ends the watcher, if any, and turns sleep back on.
    static func stop(pmset: String = rootPmset, pidFile: String = pidFile) -> String {
        "if [ -f \(pidFile) ]; then kill $(cat \(pidFile)) 2>/dev/null; rm -f \(pidFile); fi; \(pmset) -a disablesleep 0"
    }

    /// Settings → Keep Awake → Allow Without Password: a sudoers rule that lets the user run
    /// exactly the two sleep commands without a password, and nothing else.
    static let ruleFile = "/etc/sudoers.d/ember-keep-awake"

    /// The rule's line, for the user's short name; a name sudoers could misread gives the
    /// Mac's admins instead.
    static func sudoersRule(user: String) -> String {
        let isPlain = !user.isEmpty && user.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "._-".contains($0)) }
        let subject = isPlain ? user : "%admin"
        return "\(subject) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0"
    }

    /// Writes the rule to a root-only temporary file, has `visudo` check it, and only then
    /// installs it (a broken sudoers file would stop sudo working).
    static func installRule(user: String) -> String {
        "t=$(mktemp) && printf '%s\\n' '# Ember: Keep awake with the lid closed, without a password.' "
            + "'\(sudoersRule(user: user))' > \"$t\" && "
            + "/usr/sbin/visudo -cf \"$t\" && /usr/bin/install -m 0440 -o root -g wheel \"$t\" \(ruleFile); "
            + "s=$?; rm -f \"$t\"; exit $s"
    }

    static let removeRule = "rm -f \(ruleFile)"

    /// The AppleScript that runs `shell` as root after macOS asks for the admin password.
    static func appleScript(running shell: String) -> String {
        let escaped = shell.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "do shell script \"\(escaped)\" with administrator privileges"
    }

    /// Whether `pmset -g` says sleep is switched off (`SleepDisabled 1`).
    static func isSleepDisabled(pmsetOutput: String) -> Bool {
        pmsetOutput.split(separator: "\n").contains { line in
            let words = line.split(whereSeparator: \.isWhitespace)
            return words.first == "SleepDisabled" && words.last == "1"
        }
    }
}
