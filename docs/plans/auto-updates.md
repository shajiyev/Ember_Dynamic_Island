# Auto-updates Implementation Plan

**Goal:** Ember checks for, downloads and installs signed updates with Sparkle.

**Spec:** docs/specs/auto-updates.md.

**Build and test:** as in docs/plans/settings.md (clean `Build/Products` first; Debug and
Release with no warnings).

## Part 1: Sparkle

### Task 1: Set-up (the user, once)
- [x] Add the Sparkle package in Xcode (File → Add Package Dependencies…,
  `https://github.com/sparkle-project/Sparkle`, Up to Next Major from 2.0, product
  Sparkle to the Ember target).
- [x] Make the EdDSA key with Sparkle's `generate_keys` (kept in the keychain); give the
  public key for `Config/Info.plist`. Back up the private key (`generate_keys -x`) and the
  Ember Code Signing certificate (exported with its key) outside the repository.

### Task 2: The updater
- [x] Tests first: the feed address, the public key and system profiling off are in the
  built Info.plist; Check for Updates and the switch are found in search on About.
- [x] `Updater`, Check for Updates… in the menu and About, the switch. CLEAN, TEST, BUILD
  (Debug and Release, no warnings): 565 tests pass.

### Task 3: The release script
- [x] `scripts/release.sh`: version, Release build signed with Ember Code Signing, zip and
  DMG, `sign_update`, the appcast entry. Checked with a dry run that writes to
  `build/release/` only: a universal app signed with Ember Code Signing, the zip and DMG,
  a signature that `sign_update --verify` accepts (2026-11-23).
- [x] The user checks on screen (Check for Updates with an empty appcast says Ember is up
  to date; a real update before the first release, on the release checklist). Checkpoint
  and commit.
