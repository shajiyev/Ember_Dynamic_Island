# Milestone 2, feature 7 design: the file shelf (#15)

Date: 2026-11-16. Status: built 2026-11-16 and checked on screen on macOS 26.6.2. The
design changed during the checks; this spec describes what was built, and "Changed after
the checks" lists what moved from the first design.

## Goal

Drop files on the notch to keep them handy, or send them with AirDrop (the website's
promise). The shelf is a fourth panel tab that holds links to files the user parks there
while working; they can be dragged out again, opened, or sent with AirDrop.

When this is done, a user drags a PDF from Finder towards the notch: the panel opens on the
Shelf tab, with an AirDrop area on the left and the shelf on the right. Dropping on the shelf
adds the PDF; later the user drags it from the shelf into a Mail message,
and it stays on the shelf until they remove it or quit Ember.

Mocked up while designing (`.superpowers/brainstorm/`, not committed).

## What the user sees

### The Shelf tab

- A tab after Music, **Shelf**, with a tray icon (`tray.full`), in both panel layouts. The
  tab row's order is Music, Shelf, Timer, Calendar, all left of the notch.
- **Always the same view:** on the left fifth, the **AirDrop** area (a dashed frame tinted
  AirDrop blue, its symbol and "AirDrop"); on the rest, the **shelf** (a white dashed frame).
- **Items** in one row inside the shelf, **newest first**: the file's thumbnail (a real
  preview for images, PDFs and videos; the Finder icon otherwise), 44 pt, with its name
  under it (one line, shortened in the middle). The row scrolls sideways when it holds more
  than fit.
- **Clear all**, small in the shelf's top-right corner while it holds items.
- **Empty:** the shelf shows the tray symbol and "Drop files here to keep them handy".

### Dropping files

- Dragging one or more **files or folders** over the closed pill opens the panel at once on
  the Shelf tab. The area under the pointer lights up: a solid outline and a soft fill, blue
  for AirDrop, Ember rose for the shelf.
- This works even with "Open the panel on hover" off: dragging something to the notch is
  intent enough.
- **On the shelf:** the items go to the front. A file already on the shelf is not added
  twice: it moves to the front.
- **On AirDrop:** macOS's own AirDrop window opens with the items, in front, without keeping
  them; the panel closes.
- Moving the files away from the panel without dropping closes it after the usual close
  delay, as when the pointer leaves.
- Anything that is not a file (selected text, a link, an image straight out of a browser) is
  not accepted: the pill does not open for it.
- macOS can open Mission Control when something is held against the top of the screen.
  Settings → Shelf explains it and opens System Settings → Desktop & Dock, where "Drag
  windows to top of screen to enter Mission Control" can be turned off; the README has the
  same tip.

### Working with items

- **Click** selects an item (a soft highlight); **⌘-click** adds or removes an item from the
  selection; clicking empty space clears it.
- **Double-click** opens the file in its app; the panel closes.
- **Right-click:** Open, Show in Finder, Remove (for the clicked item, or the selection if it
  is part of it).
- **Under the pointer**, an item shows a small × in its top-right corner that removes it,
  and a magnifying glass in its top-left corner that shows the file in Finder (not on a
  missing item).
- **Dragging an item out** drags the selection if the item is in it, otherwise the item
  alone. Finder decides what happens, as with any file drag: into a folder on the same disk
  it moves, onto another disk it copies, ⌥ copies; into apps (Mail, Messages, chats) it
  attaches a copy. The item stays on the shelf and follows the file if it was moved. Once
  the files are let go anywhere but back on the shelf, the panel closes.
- **Dragging items onto the AirDrop area** sends them; while the shelf's own items are
  dragged, only the AirDrop area lights up, and letting them go back on the shelf does
  nothing.
- **Clear all** empties the shelf.
- **Removing never touches the file itself;** it only takes the item off the shelf.

### What an item is

- A **link to the original file** (a macOS bookmark): nothing is copied, so it costs no disk
  space and is instant for large files.
- It **follows the file** when it is moved or renamed.
- If the file is **deleted** or its disk is ejected, the item stays, dimmed, with "Missing"
  under it; it can only be removed. It comes back to life if the disk is connected again.
- Items **stay until removed or until Ember quits** (changed 2026-11-16: at first they were
  saved across restarts). Nothing is written to disk, and nothing is sent anywhere. Turning
  the Shelf off and on again while Ember runs keeps them.

### Settings

- **Settings → Shelf**, a new page in the Productivity group (after Calendar, icon
  `tray.full`, brown as in Atoll): a **Shelf** switch, **on** by default. Footer: "Drop files
  on the notch to keep them here, or send them with AirDrop. The shelf keeps links, not
  copies."
- **Off** is fully off: no Shelf tab, and the pill accepts no drops. The saved items are
  kept, so turning it on again brings them back.
- Found by the search ("shelf", "files", "drop", "AirDrop").

### Opening on the Shelf tab (added 2026-11-16)

- **While files are dragged** over the pill, the panel shows the Shelf tab at once. If they
  are moved away without dropping, it stays on Shelf until it has closed; the next ordinary
  opening shows the usual tab.
- **After files are dropped on the shelf, or a screenshot is added,** the panel opens on
  Shelf for the next **5 seconds**, even over the tab of what the wings show (the song, the
  timer). Afterwards it opens on the tab it was on before: a drop does not change the
  remembered tab. **Settings → Shelf → Stay on the Shelf tab for:** 1–20 s, default 5.
- **Settings → General → Open the panel on:** **Last tab (Recommended)**, the default, or a
  fixed tab (Music, Shelf, Timer, Calendar).
  - **Last tab:** the panel opens on the tab of what the wings show, but when it closes it
    reopens on the same tab for the next 5 seconds, whatever the wings show (for example on
    Calendar while music plays). A drag that only passed over the panel leaves the tab from
    before it as the last tab. **Stay on the last tab for** (1–20 s, default 5) shows under
    the picker only with this choice.
  - **A fixed tab** always opens, whatever the wings show and whichever tab was last.
  - Either way, a fresh alert opens its tab once (Time's up on Timer, a calendar heads-up on
    Calendar), and a fresh drop or screenshot shows Shelf (see above). A fixed tab that is
    turned off gives way to the first tab that is on.
- **Choosing a tab** in the tab row ends every hold at once.

### Screenshots (added 2026-11-16)

- A new screenshot (macOS marks screenshots in Spotlight) goes onto the shelf by itself,
  first in the row, and the panel opens on Shelf for the next 5 seconds, so it can be dragged
  out straight away.
- **Settings → Shelf → Add screenshots to the shelf**, **on** by default; off while the shelf
  is off. Like any item, it is a link: the screenshot stays where macOS saved it.
- Screenshots are saved on the Desktop by default. macOS did not ask for Desktop, Documents
  or Downloads access in the checks (macOS 26.6.2), so no permission is needed.


### Changed after the checks (2026-11-16)

- The Shelf tab is second, not fourth; the tab row was fitted left of the notch.
- One view instead of two drop targets replacing the shelf during a drag: the AirDrop area
  (20%, blue) beside the shelf (80%). The AirDrop and Clear all buttons of the bottom row
  went: AirDrop is a drop area, Clear all sits in the shelf's corner.
- Shelf items can be dragged onto the AirDrop area.
- Show in Finder on hover, beside the ×; the panel closes once dragged items are let go
  anywhere but back on the shelf.
- Screenshots go onto the shelf; the panel opens on Shelf for a while after a drop or a
  screenshot, with its own time in Settings → Shelf.
- Settings → General → Open the panel on (Last tab, or a fixed tab; #39), and the last-tab
  cooldown for every tab.
- The shelf is no longer saved: it starts empty at each launch.
- Fixed: SwiftUI sends one more drag update about 0.3 s after a drop, which lit the targets
  again; the pill ignores updates outside a drag. A tap gesture around the items emptied
  the selection a ⌘-click added to; the empty space that clears it now sits behind them.

The shelf shows nothing in the wings: the panel shows it.

## How it is built

### Why these approaches

- **Drops:** the pill's own window accepts file drags through SwiftUI's drop support, only
  over the pill's shape. Considered: watching every drag on the Mac (a global event monitor
  and the drag pasteboard) to open the panel before the pointer reaches the notch, as Boring
  Notch does. **Why not:** more code and a global monitor, for a small gain.
- **Dragging out:** a small AppKit drag source. **Why:** SwiftUI's own dragging carries one
  item at a time and does not let Finder move the file.
- **Nothing saved:** the shelf is for the work at hand, so it starts empty at each launch.
  Items are still bookmarks, so they follow moved files while Ember runs.

### Files

New folder `Ember/Shelf/`:

| File | Job |
|---|---|
| `ShelfItems.swift` | The pure rules: the item list (`ShelfItem`: an id, its bookmark and last path), adding (newest first, a file already there moves to the front), removing, clearing; the selection after a click or ⌘-click; which items a drag takes (the selection if the dragged item is in it, otherwise the item alone); `ShelfDropTarget`, the area at a drop position (AirDrop left of 0.24, the shelf right of it). |
| `ShelfBookmarks.swift` | Turning dropped files into bookmarks and bookmarks back into file URLs (following moved files, noticing missing ones). The only file-system code. |
| `ShelfModel.swift` | The shelf's state while Ember runs: items, selection, where each file is now, thumbnails; add, remove, clear, open, show in Finder, AirDrop. |
| `ShelfThumbnails.swift` | Thumbnails from Quick Look's thumbnail service, falling back to the Finder icon. |
| `ShelfPanelView.swift` | The Shelf tab: the AirDrop area, the shelf with its item row or empty line, Clear all, the hover buttons. |
| `ShelfDropFrame.swift` | The dashed frame of each area, lit while files are over it; `ShelfLook`. |
| `ShelfItemInteraction.swift` | An item's AppKit side: click, ⌘-click, double-click, hover, the right-click menu, and the drag source for dragging items out. |
| `ScreenshotWatcher.swift` | Notices new screenshots through Spotlight (`kMDItemIsScreenCapture`). |

Changed:
- `Ember/Pill/PillState.swift`, `PillController.swift`, `PillView.swift`: a file drag over
  the pill opens it at once (whatever the hover setting) and holds it open while the drag
  lasts; leaving starts the close delay. While a drag is over the open panel, the pill tells
  its content where (`fileDragPosition`, 0…1 across its width), so the content can show the
  area under the files; dropped files go to the app (`onFileDrop`, with that position). It accepts
  drags only while `acceptsFileDrags` is on. The pill never refers to the shelf.
- `Ember/Panel/PanelTabs.swift`: the `shelf` tab; `PanelSelection`'s holds (Shelf during a
  drag and after a drop or screenshot, the last tab after closing), the default tab and the
  alert tab.
- `Ember/Panel/PanelView.swift`: the Shelf tab.
- `Ember/Settings/AppSettings.swift`, `SettingsPage.swift`, `SettingsSearch.swift`,
  `SettingsRow.swift`, `GeneralPage.swift`, `FeaturePages.swift`: the Shelf page (switch,
  screenshots, Shelf time, the Mission Control tip) and General's opening tab and last-tab
  time.
- `Ember/AppDelegate+Shelf.swift` (new): dropped files and screenshots to the shelf or
  AirDrop. `AppDelegate+Settings.swift`, `EmberApp.swift`: create the shelf and the
  screenshot watcher, connect a drag to the Shelf tab, apply the settings, and pass alerts
  as the panel's alert tab.

## Testing

Unit tests, written first:
- `ShelfItemsTests`: adding puts items first, in the dropped order; a file already there moves
  to the front without a duplicate; removing one or several; clearing; click and ⌘-click
  selection; dragging an unselected item takes it alone, a selected one takes the
  selection; which area a drop position falls in, and that the shelf's own items only go
  to AirDrop.
- `ShelfBookmarksTests`: a dropped file is found again; a moved file is followed; a deleted
  file is missing.
- `PillModelTests`, `PillControllerTests`: a file drag opens the pill even with hover off;
  leaving starts the close delay; the panel stays open while the drag is over it; a late
  drag update after a drop does not light the targets again.
- `PanelTabsTests`: the Shelf holds, the last-tab hold, a fixed default tab, alerts.
- `AppSettingsTests`, `SettingsSearchTests`: the switches and times (defaults, limits,
  saving), the opening tab, and their search words.

Checked on screen by the user on macOS 26.6.2 (all passed): the tab and its look in both
layouts; dropping on the shelf and on AirDrop, with hover on and off; non-files refused;
selecting, ⌘-click, double-click, the right-click menu, Show in Finder, ×, Clear all;
dragging out to Finder (move, ⌥ copy), Mail and AirDrop, and back onto the shelf; renamed,
moved and deleted files; screenshots on and off; the opening tab and both cooldowns; quit
and reopen (empty); no Files & Folders prompt; the Desktop & Dock button; the Shelf switch;
Music, Timer, Calendar and the volume strip unchanged.

## Risks to check early

- **Drops on the pill's window:** a non-activating, transparent panel above the menu bar must
  receive drag events over the pill's shape and not swallow them elsewhere.
- **Finder moving a file dragged out:** the drag source must offer move as well as copy, and
  Finder must honour it.
- **AirDrop from a menu bar app:** the sharing service must show its window in front.
- **Files & Folders permission:** reading a shelved file in Desktop, Documents or Downloads
  (its thumbnail, for example) might make macOS ask for access. Checked: no prompt appeared
  (macOS 26.6.2), so no prompt text or README line is needed.

## Code reused from Atoll / Boring Notch

Level 1 (see CLAUDE.md): both have a shelf; the ideas (an AirDrop drop area beside the
shelf, bookmarks, Quick Look thumbnails) are written our own way. If a snippet is adapted during building, it is
noted here.

## Not in this feature

Text, links and browser images on the shelf; copies of files; Quick Look previews; a count
in the wings; sharing other than AirDrop; dragging a file onto the pill to open the panel
before the pointer reaches the notch.
