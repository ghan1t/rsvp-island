# Code map

## Application lifecycle

- `RSVPIsland/RSVPIslandApp.swift` — SwiftUI entry point and window-style `MenuBarExtra`.
- `RSVPIsland/Application/AppDelegate.swift` — shortcut registration, screen-change observation, and termination cleanup.
- `RSVPIsland/Application/AppContainer.swift` — dependency construction and application-wide object ownership.

## Text acquisition

- `TextInput/AccessibilityTextProvider.swift` — trust status, permission prompt, secure-field rejection, selected text, and focused-window frame.
- `TextInput/ClipboardTextProvider.swift` — read-only plain-text clipboard access.
- `TextInput/TextAcquisitionCoordinator.swift` — selection-first fallback policy and source application capture.
- `TextInput/AcquiredText.swift` — acquisition result and source metadata.

Change fallback rules in the coordinator, not in `ReaderController`.

## RSVP reader

- `Reader/RSVPTokenizer.swift` — whitespace extraction, Unicode ORP calculation, punctuation delays, and paragraph detection.
- `Reader/RSVPToken.swift` — rendered token segments and delay multiplier.
- `Reader/ReaderController.swift` — session state machine, `ContinuousClock`-style task timing, cancellation, keyboard controls, and focus restoration.
- `Reader/ReaderRootView.swift` — reader surface layout and presentation-state rendering.
- `Reader/ORPWordView.swift` — fixed-center red pivot rendering.
- `Reader/ReaderAnimations.swift` — shared animation and hold durations.

Tokenizer behavior should always be changed together with `RSVPIslandTests/Reader/RSVPTokenizerTests.swift`.

## Panel and displays

- `Display/DisplayResolver.swift` — target-screen selection, optional auxiliary notch-area handling, fallback notch size, and canvas geometry.
- `Display/DisplayMetrics.swift` — resolved geometry passed to the panel and view.
- `Panel/ReaderPanelFactory.swift` — window level, Spaces/full-screen behavior, transparency, and mouse passthrough.
- `Panel/ReaderPanelController.swift` — panel lifetime, SwiftUI hosting, positioning, focus, and display-change handling.
- `Panel/ReaderPanel.swift` — key-but-never-main panel behavior.

Change visible shape/layout in `ReaderRootView`; change AppKit window behavior in `ReaderPanelFactory` or `ReaderPanelController`.

## Settings

- `Settings/ReaderSettingsStore.swift` — `UserDefaults`, WPM clamping, onboarding flags, and disabled-by-default login preference.
- `Settings/SettingsMenuView.swift` — menu-bar controls and actions.
- `Settings/LoginItemController.swift` — actual `SMAppService.mainApp` status and opt-in registration.
- `Settings/ShortcutNames.swift` — default Control–Option–R shortcut.

Settings behavior tests are in `RSVPIslandTests/Settings/ReaderSettingsStoreTests.swift`.
