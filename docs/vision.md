# Vision

## What
Ember turns the MacBook notch into a living status surface. At rest it is a black pill
that blends into the notch. When something happens (music playing, charging, a timer
running) a warm glow and compact info appear beside the notch. Hover or click and it
expands into controls and quick tools.

Brand: the logo is a white block "E" on a glowing ember-orange background
(`assets/Ember_logo.png`). On screen, the pill is black and lights up with a warm ember
glow when something is happening.

## Why
- A polished tool the author uses every day.
- A public portfolio project showing a real native macOS app built with AI assistance.

## Users
1. The author (14" MacBook Pro, M3 Pro).
2. Members of the public who download Ember from GitHub Releases.

## Goals
- Feels native: smooth SwiftUI animations, low CPU/battery use, no jank.
- Easy to install for free: DMG on GitHub Releases, auto-updates, and clear first-launch
  instructions (Ember is not notarized, so macOS shows a warning the first time).
- Clean, readable open-source codebase and docs.

## Non-goals
- Mac App Store distribution (notch apps need APIs and window behaviour the sandbox forbids).
- iOS/iPadOS versions.
- Using Atoll / Boring Notch branding. (Their GPL-3.0 code may be reused with credit.)

## Supported Macs
- macOS 15 (Sequoia) or later; developed and tested on macOS 26.
- v1: MacBooks with a notch, built-in display only. Floating pill for other screens comes later.
