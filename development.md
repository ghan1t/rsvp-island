# Development and verification

## Environment

- Xcode 26.5 with the full macOS SDK is currently used.
- Deployment target: macOS 14.0.
- Swift language mode: Swift 6 with complete strict concurrency checking.
- App Sandbox: disabled for this prototype.
- Bundle identifier: `ch.ghanit.rsvpisland`.
- `LSUIElement` is enabled, so the app has no Dock icon.
- KeyboardShortcuts is pinned to `3.0.1` up to the next major version.

The Xcode project uses file-system-synchronized source roots. New Swift files beneath `RSVPIsland/` or `RSVPIslandTests/` are normally added to their corresponding target automatically.

## Build and test

From the repository root:

```sh
xcodebuild \
  -project RSVPIsland.xcodeproj \
  -scheme RSVPIsland \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

xcodebuild \
  -project RSVPIsland.xcodeproj \
  -scheme RSVPIsland \
  -destination 'platform=macOS' \
  test
```

For interactive testing, open `RSVPIsland.xcodeproj`, select the `RSVPIsland` scheme and **My Mac**, then press Command-R. Use **Product → Clean Build Folder** after project membership or package changes.

Alternatively, build and launch the app directly from the current worktree:

```sh
./build-and-run.sh
```

This uses the signing configuration from `Configuration/Signing.xcconfig`. To build with an ad-hoc signature instead:

```sh
./build-and-run-ad-hoc.sh
```

Both scripts use separate directories beneath `.build/`, stop any running development copy, and launch the newly built app.

## Manual smoke test

1. Confirm the `textformat` menu-bar icon appears and there is no Dock icon.
2. Copy text and choose **Read Clipboard Now**.
3. Grant Accessibility access, select text in another app, and press Control–Option–R.
4. Verify Space pauses, Escape closes, Up/Down changes speed, and Left/Right steps only while paused.
5. Confirm focus returns to the originating application.
6. Test both a notched display and a non-notched/external display when available.

## Known development notes

- Launch at login is disabled by default. Do not auto-register it during development.
- Console messages about `com.apple.linkd.autoShortcut` can appear even though this app defines no App Intents. They are macOS service noise and do not affect KeyboardShortcuts.
- Login-item registration requires a stable signed app bundle and can fail from transient build locations; failures are nonfatal and displayed in the menu.
- The project has automated tokenizer and settings tests. Accessibility, focus, multi-display geometry, Spaces, and full-screen behavior still require manual integration testing.
