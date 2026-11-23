# Auto-updates (#27)

Agreed with the user 2026-11-23.

## What and why

Bug fixes and new versions reach users without them looking for them. Ember is free and
not notarized, so it is not in the App Store; it updates itself with **Sparkle**, the
open-source updater most Mac apps outside the App Store use (MIT licence, fine with
GPL-3.0). It is Ember's first outside dependency, added as a Swift package.

## How it works for the user

- Once a day Ember reads a small file online, the **appcast**, which lists its versions.
  When a newer one is there, Sparkle's own window shows its notes with **Install Update**,
  **Remind Me Later** and **Skip This Version**. Install downloads it, replaces Ember and
  opens it again. Nothing installs without the user's click.
- Sparkle asks on the second launch whether to check automatically (its standard
  question); the answer can be changed in Settings.
- **Check for Updates…** in Ember's menu bar menu and in Settings → About checks at once.
- **Settings → About → Check for updates automatically** (on once agreed): the daily check.
- The check sends nothing about the Mac: Sparkle's anonymous system profile stays off. It
  is the one network call the website's privacy promise allows.

## Trust

- Every update is signed with an **EdDSA private key** made once by Sparkle's
  `generate_keys`. It lives only in the login keychain of the Mac that makes releases;
  never in the repository, never on GitHub's servers. Ember carries the matching public
  key (`SUPublicEDKey`) and refuses any download not signed with it.
- The app itself is signed with the self-made **Ember Code Signing** certificate
  (decisions 2026-11-15). Releases use the same certificate, so macOS sees the same app
  after an update and keeps its permissions (Accessibility, Automation, Calendar).
- **Both keys must be backed up** outside the Mac and outside the repository (an encrypted
  disk or a password manager). Losing the EdDSA key means installed copies can never be
  updated again; losing the certificate means every user re-allows the permissions after
  the next update.

## Where things live

| What | Where |
|---|---|
| The appcast | `https://www.getember.online/appcast.xml`, the file `site/appcast.xml`, deployed with the website. Ember's own address, so hosting can change without breaking installed copies. |
| The update (zip) and the DMG | The GitHub Release of each version (`…/releases/download/v1.1/Ember-1.1.zip`). |
| The keys | The release Mac's login keychain, plus the backups. |

## Releasing a version

`scripts/release.sh <version>` on the release Mac:
1. sets the version (marketing version, and the build number one higher), builds Release
   signed with Ember Code Signing;
2. makes `Ember-<version>.zip` (for Sparkle) and `Ember-<version>.dmg` (for the website and
   first downloads) in `build/release/` (ignored by git);
3. signs the zip with Sparkle's `sign_update` (the key from the keychain);
4. adds the version to `site/appcast.xml` with its signature, size, the download address
   and a link to its release notes.

Then, by hand: create the GitHub Release `v<version>` with the zip and the DMG and its
notes, and commit (the version change and the appcast). The site deploys the appcast;
installed copies see it within a day.

## Before the first release

- Check a real update: install version N on a test account, publish N+1, update from the
  app, and confirm the permissions are kept.

## Not in this feature

- Silent installs, beta channels, delta updates.
- Building releases on GitHub's servers (the keys would have to go there).

## How it is built

| Unit | File | What it does |
|---|---|---|
| Updater | `Ember/Updates/Updater.swift` | Sparkle's standard updater controller; Check for Updates; the automatic check switch. |
| Info | `Config/Info.plist` (outside the synced folder) | Sparkle's keys: `SUFeedURL`, `SUPublicEDKey`, `SUEnableSystemProfiling` (off). Merged with the generated Info.plist. |
| Menu and About | `EmberApp.swift`, `AboutPage.swift` | Check for Updates…, the switch. |
| Release | `scripts/release.sh` | The steps above. |
