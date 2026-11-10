# Ember — project guide for Claude

Ember is a native macOS "Dynamic Island" for the MacBook notch: a black pill that sits
around the notch, glows when something is happening, and expands into media controls,
live activities and quick tools. It is intended for public, open-source release.

## Stack
- Swift + SwiftUI, with AppKit for the notch window (borderless `NSPanel`) — *proposed, see docs/decisions.md*
- Xcode project lives in this repo; app / target / bundle name: **Ember**
- License: **GPL-3.0** (see LICENSE)
- Minimum macOS: **15.0** (deployment target). Developed and tested on macOS 26.
  Newer-only APIs must be wrapped in `if #available(...)`.
- Distribution: free only — DMG on GitHub Releases + Sparkle; no paid Apple Developer
  account, not notarized. Never commit a signing Team ID or keys.
- Displays: built-in notch display only in v1 (floating pill for other screens is feature #28, later).
  Keep notch size/position computed in one place so #28 stays cheap.

## Hard rules
- **Reusing Atoll / Boring Notch code (both GPL-3.0, like Ember):** allowed. Three levels:
  1. Same idea / same Apple APIs, written our own way → nothing needed.
  2. Snippets or functions copied/adapted into *our* files → no per-file header; covered
     by the project-wide credit in the README ("portions derived from Atoll and Boring Notch").
  3. A whole file copied mostly as-is → keep its original copyright header intact. (Rare.)
  Never use their name/logo/icons/assets as Ember branding, and scrub copied code of their
  identifiers: bundle IDs, update-feed URLs, Sparkle keys, Discord/donation links,
  analytics, user-facing "Atoll" strings.
- **Public repo:** never commit secrets, API keys, personal paths, personal data, or
  signing credentials. No absolute `/Users/...` paths in code or docs.
- Code and docs must be readable by strangers: clear names, short files, no dead code.
- The user makes every commit. Claude prepares file list + message only.

## Docs index (read on demand)
- `docs/vision.md` — what & why, users, goals, non-goals
- `docs/architecture.md` — modules, data flow, patterns
- `docs/roadmap.md` — **Current status** at top, then milestones
- `docs/features.md` — feature inventory + status
- `docs/decisions.md` — dated decision log
- `docs/plans/` — one implementation plan per feature

## Project-specific checkpoint items
- Confirm no secrets / personal paths in the diff (`git diff --cached | grep -i -E "users/|api[_-]?key|token|secret"`).
- If a new permission (Accessibility, Calendar, Camera…) was added, document it in README.
- Note the macOS version the change was tested on.
