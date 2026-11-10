# Architecture

> Status: not designed yet. Filled in after the v1 design is approved.

## Stack (proposed)
- Swift, SwiftUI for views, AppKit for window management.
- Single macOS app target `Ember`. A unit-test target is added with the first test.

## Repository layout
- `Ember.xcodeproj/` — Xcode project. Build settings live in `project.xcproj` (plain text).
- `Ember/` — app source code and assets. Xcode syncs this folder automatically.
- `assets/` — logo and other repository artwork (not bundled into the app).
- `docs/` — planning documents.

## Modules
TODO — expected areas: notch window & geometry, expand/collapse state machine,
feature modules (media, live activities, …), settings, updater.

## Data flow
TODO

## Conventions
TODO — folder layout, naming, how a feature module plugs into the notch.
