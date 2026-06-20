# RSVP Island implementation guide

RSVP Island is a Swift 6 menu-bar application targeting macOS 14+. It reads selected text through Accessibility, falls back to the clipboard, and presents an ORP-aligned RSVP reader in a borderless panel attached to the top of the chosen display.

Start with [code-map.md](code-map.md) when locating a change and [development.md](development.md) before building or testing.

## Runtime flow

1. `AppDelegate` registers the global shortcut defined in `ShortcutNames`.
2. `ReaderController` asks `TextAcquisitionCoordinator` for text before taking focus.
3. Accessibility selection wins; clipboard text is the fallback.
4. `RSVPTokenizer` creates Unicode-safe tokens, ORP segments, and timing multipliers.
5. `DisplayResolver` chooses the display and calculates notch/canvas geometry.
6. `ReaderPanelController` hosts `ReaderRootView` in a transparent `NSPanel`.
7. `ReaderController` drives animation, playback, keyboard controls, cleanup, and focus restoration.

`AppContainer.shared` constructs and retains the application services. There is one reader session and one lazily created panel.

## Important constraints

- Text stays in memory and is cleared when a session closes.
- Do not synthesize Command-C or modify the clipboard.
- Do not add networking, telemetry, OCR, ScreenCaptureKit, private APIs, or a helper daemon.
- The panel window frame is fixed; SwiftUI content performs the visible animation.
- Launch at login is disabled by default during development and must remain opt-in.
- Accessibility code uses `@preconcurrency import ApplicationServices` and remains main-actor isolated.

## Brave Browser

Brave may not expose webpage content through the macOS Accessibility API by default. If selected text always falls back to the clipboard:

1. Open `brave://accessibility` in Brave.
2. Enable **Native accessibility API support**.

After enabling it, Brave should expose the active webpage and its selected text to RSVP Island.
