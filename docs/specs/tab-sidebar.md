# Tabs in a sidebar (#48)

Agreed with the user 2026-11-27. Status: built 2026-11-27, checked on screen by the user on macOS 26.6.2. Built after Keep awake's tab
(docs/specs/keep-awake.md, "The tab"), so the rail holds that tab from the start.

## Goal

The open panel's tabs can sit in a **sidebar** on the left, a rail, instead of the top row
beside the notch. Today's top row stays the default; the sidebar is a choice in Settings,
like Compact and Wide. Why: the user likes how it looks (more like an app, the tabs read as a
list), and saw it in another notch app (name unknown; only the idea is borrowed).

When this is done, a user picks Sidebar in Settings → General → Tabs, opens the panel, and
sees the tabs in a rounded strip down its left side, the battery and the gear alone at the
top right, and every tab's content exactly as roomy as before.

Mocked up while designing (`.superpowers/brainstorm/`, not committed): the rail's look
(plain column, column with a line, rail, glow marker: **rail** chosen) and the top row
(rail under the top row, rail from the top edge, split top row: **from the top edge**
chosen), then the tab's name (in the room left of the notch, beside the full-height rail, in
small grey capitals: **10 pt capitals** chosen).

## What the user sees

### The rail

```
┌────────────────────────────────────────────────────┐
│ ╭──╮ MUSIC         ▓▓▓▓▓ notch ▓▓▓▓▓       [73] ⚙  │
│ │♪ │                                               │
│ │⏱ │   [cover]  Song title                         │
│ │📅│            Artist                             │
│ │🗂 │   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━         │
│ │☕ │          ⏮      ▶      ⏭                    │
│ ╰──╯                                               │
└────────────────────────────────────────────────────┘
```

- A slightly lighter rounded strip (white at about 7%) down the panel's left side, from near
  the panel's top edge (beside the notch, where the top row's left side was) to near its
  bottom. About 36 pt wide, 24 pt in from the panel's edge (clear of the top corner's flare, like the top row).
- The tabs in a column inside it, in the rail's own order (see Settings). Same icons, sizes
  and behaviour as the top row's tabs: the chosen one in the soft white capsule (white at
  15%), the others at 55% white, brighter on hover; the name on hover and for VoiceOver.
- The **top row** holds the battery (when on) and the gear on the right, and on the left,
  between the rail and the notch, **the name of the tab shown** (see below).

### The tab's name

- The name of the tab the panel shows (`MUSIC`, `TIMER`, `KEEP AWAKE`), in **10 pt semibold
  capitals**, letters spaced a little (about 0.8 pt), **white at 50%**: a quiet label, not a
  title. Chosen 2026-11-27 from six mocked-up sizes and styles (capitals or normal letters,
  10–13 pt).
- In the top row, level with the middle of the rail's first tab (23 pt from the panel's top, 22 with regular icons;
  moved down from the notch's middle at the user's first look, 2026-11-27), starting in line
  with the content's left edge (right of the rail).
- It follows the tab shown, also when the panel shows Shelf by itself (a drop, a screenshot).
- A name too long for the room before the notch ends with "…". Today's names all fit.
- Only in Sidebar mode; the top row placement has no name.
- The **content** (each tab's body) sits right of the rail, at the same height as today.

### Many tabs

Changed 2026-11-27 at the user's first look: no scrolling. Like the top row, the icons get
smaller when the tabs do not fit (a scrolling rail with edge fades was built first, then
dropped).
- **Large icons** (22 pt with the capsule) while they fit, with the room left spread between
  them from 2 to 4 pt; **regular icons** (20 pt) otherwise, 2 pt apart. In the 202 pt panel:
  up to 7 tabs large, 8 regular (from 2026-11-27 at 187 pt: 6 large, 7 regular).
- The rail never scrolls; every tab is always in sight.
- **Limit:** 8 tabs fit (7 at 187 pt). The planned list has 9 (with Clipboard, Color picker, Webcam
  mirror and Claude Code usage); the 9th needs a decision when it comes (a smaller size, or
  fewer tabs).

### The panel's width

- In Sidebar mode the panel is **wider by the rail's room (about 42 pt)**, so every tab's
  content keeps exactly the room it has in the top row. Compact at its default width goes
  from 460 to about 502 pt.
- This applies to Compact and Wide alike. The Width slider keeps its ranges and sets the
  width without the rail; the rail is added on top.
- The panel stays centred on the notch, so the content sits about 24 pt right of the notch's
  centre. To be checked by eye.
- The width rule (the panel is never narrower than the top row needs) counts only the battery
  and the gear in Sidebar mode, since no tabs sit beside the notch.

### Settings → General → Tabs

- At the top of the Tabs section, two clickable preview cards side by side, **Top row** and
  **Sidebar**, drawn in the app like the Panel layout cards: a small drawing of the panel
  with the tabs in the top row or in the rail, the name under it. The chosen card has the
  Ember rose outline. Top row is the default.
- Under the cards, the drag preview follows the choice:
  - **Top row:** today's drawing of the top of the panel, unchanged.
  - **Sidebar:** a drawing of the panel's left part with the rail and the tab's name, at real
    size and at the icon size the rail uses. Dragging a tab onto another puts it just before that one; dropping it in
    the rail's empty part puts it at the end. A tab whose feature is off is drawn faded and
    keeps its place, as in the top row's drawing.
- **Each placement keeps its own order.** Arranging the rail never changes the top row and
  the other way round. A tab missing from a saved order (a new feature) joins the end of it.
- A new choice applies the next time the panel opens, like Panel layout.
- Reset to Defaults on General brings back Top row and the rail's standard order.
- Search finds the choice (Tab position) with "sidebar", "rail", "top row".

## Not in this feature

- A rail on the right side.
- Tab names written beside the icons in the rail (it would need about 100 pt).
- A taller panel when many tabs are on (the icons get smaller instead).
- Scrolling the rail (built, then dropped on 2026-11-27).
- Placement per layout (the choice applies to Compact and Wide together).

## How it is built

| Unit | File | What it does |
|---|---|---|
| Placement | `Ember/Panel/TabPlacement.swift` (new) | `TabPlacement` (`topRow`, `sidebar`) and `RailLayout`: the rail's width, inset, room added to the panel, the tabs' size and gap for a number of tabs. Pure, `nonisolated`. |
| Rail order | `Ember/Panel/TabArrangement.swift` | Gains `RailArrangement`: one list of tabs read from saved names (unknown names and repeats dropped, missing tabs at the end) and moving a tab before another or to the end. Pure. |
| Rail view | `Ember/Panel/PanelRail.swift` (new) | The rail: the strip, the tabs (one tab button, pulled out of `PanelTabRow` in `PanelTabs.swift` so the top row and the rail share it), sized by `RailLayout`. |
| Panel | `Ember/Panel/PanelView.swift` | In Sidebar mode, the rail beside the content, and a top row with the tab's name on the left and the battery and the gear on the right. |
| Settings | `Ember/Settings/AppSettings.swift` | `tabPlacement` (top row) and `railArrangement` (saved as `tabsRail`); `panelSize` adds `RailLayout.panelRoom` in Sidebar mode; `openSideRoom` counts no tabs in Sidebar mode; `shownTabs` follows the placement's order; Reset to Defaults. |
| Settings page | `Ember/Settings/GeneralPage.swift`, `LayoutCards.swift`, `TabsPreview.swift`, `SettingsSearch.swift` | The Top row / Sidebar cards; the rail drawing with dragging; the search words. |

`NotchGeometry` and `PillController` do not change: they are given the wider `openSize` as
today.

## Key files

- `Ember/Panel/TabPlacement.swift` — `TabPlacement`; `RailTabs`; `RailLayout`: the rail's
  place and width, `contentLeading` (74), `panelRoom` (42), `tabRoom`, `tabs(count:panelHeight:)`
  (large icons while they fit, else regular; gaps 2–4 pt), `firstTabCenter(size:)`, `nameRoom`.
- `Ember/Panel/TabArrangement.swift` — `RailArrangement`, the rail's own order.
- `Ember/Panel/PanelRail.swift` — `PanelRail` (the strip and its tabs, no scrolling) and
  `TabNameLabel`.
- `Ember/Panel/PanelView.swift` — the rail as an overlay (read first by VoiceOver), the name
  in the top row level with the first tab, the content's leading inset.
- `Ember/Settings/AppSettings.swift` — `tabPlacement`, `railArrangement`, `tabOrder`,
  `panelSize` (+ `RailLayout.panelRoom` with the sidebar), `openSideRoom` (no tabs with the
  sidebar).
- `Ember/Settings/TabPlacementCards.swift`, `RailPreview.swift`, `LayoutCards.swift`
  (`ChoiceCard`, shared with Panel layout), `TabsPreview.swift` (`TabChip`, also vertical),
  `GeneralPage.swift`, `SettingsSearch.swift` (`tabPlacement`, "Tab position").
- `Ember/Shelf/ShelfItems.swift` — `ShelfDropTarget(position:panelWidth:contentLeading:)`:
  the AirDrop / keep split follows where the content starts (`AppDelegate+Shelf.swift`,
  `ShelfPanelView.swift`).

## Gotchas

- Anything placed by a share of the panel's width must allow for the rail: the shelf's drop
  split was wrong in Sidebar mode until it followed the content's leading inset.
- `PillController.openSize` keeps its own copy of the panel's height (the pill module does
  not refer to the panel module); `PanelHeightTests` keeps the two in step.
- 8 tabs fit in the rail (7 at 187 pt); a 9th needs a decision (see "Many tabs").
- `shownTabs` decides the opening tab's fallback and the "first tab" order everywhere; in
  Sidebar mode it must follow the rail's order, not the top row's.
- The top row's `TopRowLayout` must not count tabs in Sidebar mode, or the panel grows for
  tabs that are not in the row.
- The name's room is the space between the rail and the notch, about 80 pt at the default
  width on a 185 pt notch, less with More Space's wider notch. Tabs to come need short
  titles (Claude Code usage in capitals would not fit whole).

## Tests

Unit tests, written first:
- `RailArrangementTests`: reading saved names (unknown and repeated names dropped, missing
  tabs at the end); moving a tab before another and to the end.
- `TabPlacementTests` (`RailLayout`): large icons up to 7 tabs, regular for 8, the gaps; the
  room added to the panel; the name's room and height.
- `AppSettingsTests`: Top row is the default; the placement and the rail's order survive a
  relaunch; Reset to Defaults brings both back; `panelSize` is wider by the rail's room in
  Sidebar mode; `openSideRoom` counts no tabs in Sidebar mode; `shownTabs` follows the
  rail's order in Sidebar mode.
- `SettingsSearchTests`: "sidebar", "rail" and "top row" find the choice.

Manual checklist (in the plan), on macOS 26:
1. A new install shows the top row, unchanged.
2. Sidebar in Settings: the next opening shows the rail from the top edge, the tab's name
   beside it in small grey capitals (lined up with the content, changing with each tab and
   when the shelf takes over), the battery and the gear at the top right, the content as
   roomy as before, in Compact and in Wide.
3. Dragging in the rail drawing reorders the rail; the top row's order does not change, and
   switching back and forth keeps both.
4. The rail does not move under two fingers. (Smaller icons for 8 tabs cannot be seen with
   today's 5 tabs; the rule is covered by tests.)
5. Turning features off and on: their tabs leave and come back in place in both orders.
6. The keyboard shortcut, full-screen apps (the bare notch) and closing onto a live activity
   look right with the rail.

## Last updated

2026-11-27: designed and built; at the user's first look the name moved level with the
first tab, scrolling was dropped for smaller icons, and the panel became 202 pt tall.
