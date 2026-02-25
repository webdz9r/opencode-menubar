# AGENTS.md

This document describes the opencode-menubar codebase for AI agents and maintainers.

## Project Overview

opencode-menubar is a native macOS menubar application that manages the `opencode web --mdns` server process. It provides a system tray icon with a dropdown menu to start, stop, and monitor the server. The app has no main window and no dock icon — it lives entirely in the menubar.

## Technology

- **Language:** Swift (compiled with `-swift-version 5` language mode using the Swift 6 toolchain)
- **Frameworks:** Cocoa (AppKit), ServiceManagement (Login Items)
- **Build system:** Makefile with `swiftc` — no Xcode project required
- **Target:** macOS 13.0+ (arm64)
- **Bundle ID:** `com.opencode.taskbar`
- **Code signing:** Developer ID Application certificate (see Makefile for identity)
- **Distribution:** Signed and notarized via GitHub Actions; also installable from source

## Architecture

The app follows a simple delegate pattern with three components:

```
main.swift → AppDelegate → ServerManager
                ↑                ↓
                └── delegate ────┘
```

### Sources/main.swift
Entry point. Creates the `NSApplication`, sets the activation policy to `.accessory` (hides dock icon), assigns the `AppDelegate`, and starts the run loop. This file should remain minimal.

### Sources/AppDelegate.swift
Owns the UI layer. Responsibilities:
- **NSStatusItem**: Creates and manages the menubar icon (custom-drawn circle with "OC" text)
- **Icon rendering**: Draws the icon programmatically via `NSImage` drawing block using `NSBezierPath` (circle) and `NSAttributedString` ("OC" text). Uses `NSAppearance.currentDrawing()` to detect light/dark mode at render time so colors always contrast with the menubar.
- **NSMenu**: Builds the dropdown menu with status, start/stop actions, login item toggle, version link, and quit
- **State sync**: Implements `ServerManagerDelegate` to update the menu and icon whenever the server state changes
- **Login Items**: Uses `SMAppService.mainApp` to register/unregister as a macOS Login Item
- **Version link**: Displays the current version (`appVersion` constant) at the bottom of the menu; clicking it opens the GitHub releases page

Key constants:
- `AppDelegate.appVersion` — the current version string (bump this on each release)
- `AppDelegate.releasesURL` — the GitHub releases page URL

Key MARK sections:
- `App Lifecycle` — `applicationDidFinishLaunching`, `applicationWillTerminate`
- `Status Item Setup` — `setupStatusItem()`, `updateIcon(running:)`
- `Menu Construction` — `buildMenu()`, `updateMenuState()`
- `Actions` — `startServer()`, `stopServer()`, `toggleLaunchAtLogin()`, `openReleases()`, `quitApp()`

### Sources/ServerManager.swift
Owns the process lifecycle. Responsibilities:
- **Binary resolution**: Checks `/opt/homebrew/bin/opencode`, then `/usr/local/bin/opencode`
- **Process management**: Uses Foundation `Process` to spawn `opencode web --mdns`
- **State machine**: `ServerState` enum with four states: `stopped`, `starting`, `running`, `stopping`
- **Graceful shutdown**: Sends SIGTERM, waits 5s, sends SIGINT, waits 2s, then SIGKILL as last resort
- **Crash detection**: `terminationHandler` detects unexpected exits and resets state
- **Delegate notifications**: State changes dispatch to `ServerManagerDelegate` on the main thread

## Menubar Icon

The icon is **not** an SF Symbol or image asset. It is drawn programmatically in `updateIcon(running:)` every time the server state changes.

### How it renders
1. Creates an 18x18 `NSImage` with a drawing block
2. Detects the current appearance via `NSAppearance.currentDrawing().bestMatch(from:)`
3. Draws a filled circle (`NSBezierPath(ovalIn:)`) with a color that contrasts the menubar
4. Draws "OC" text centered in the circle using `NSAttributedString`
5. Sets `image.isTemplate = false` so macOS does not override colors

### Color rules

| State | Light Mode | Dark Mode |
|-------|-----------|-----------|
| Stopped | Black circle, white "OC" | White circle, black "OC" |
| Running | Black circle, green "OC" | White circle, green "OC" |

### Modifying the icon
- To change the icon size, edit the `NSSize(width: 18, height: 18)` value
- To change the font, edit the `NSFont.systemFont(ofSize: 8.5, weight: .bold)` call
- To add new states (e.g. error), add a color branch in the `if running` / `else` block
- Do **not** set `image.isTemplate = true` — it will strip custom colors

## Resources/Info.plist

Bundle configuration. Key entries:
- `LSUIElement = true` — hides the app from the dock
- `NSSupportsAutomaticTermination = false` — prevents macOS from killing the app
- `NSSupportsSuddenTermination = false` — ensures `applicationWillTerminate` is called for cleanup

## Build System

The `Makefile` handles everything. No Xcode project exists or is needed.

| Target | Command | Description |
|--------|---------|-------------|
| `build` | `make build` | Compiles Swift, creates `.app` bundle in `build/`, ad-hoc code signs |
| `clean` | `make clean` | Removes `build/` directory |
| `sign` | `make sign` | Re-signs the `.app` with Developer ID certificate + hardened runtime |
| `notarize` | `make notarize` | Submits to Apple for notarization, waits, staples the ticket |
| `release` | `make release` | Full pipeline: `build` → `sign` → `notarize` |
| `install` | `make install` | Full pipeline + copies to `~/Applications/` + launches |
| `install-unsigned` | `make install-unsigned` | Builds with ad-hoc signing only (no Developer ID needed) |
| `uninstall` | `make uninstall` | Kills the process, removes from `~/Applications/` |
| `run` | `make run` | Builds and runs from `build/` without installing |

The build compiles all `Sources/*.swift` files together with `swiftc`, then assembles the `.app` bundle manually (MacOS binary + Info.plist + code signature).

## Code Signing and Notarization

### Local signing

The Makefile contains the signing identity and team ID as `SIGNING_IDENTITY` and `TEAM_ID` variables. These match the Developer ID Application certificate installed in the maintainer's Keychain.

For local `make install` (signed + notarized), you need:
1. The Developer ID Application certificate installed in your Keychain
2. An App Store Connect API key (`.p8` file) in the project root
3. A `.env` file with `APP_STORE_KEY_ID` and `APP_STORE_ISSUER_ID`

For contributors without the certificate, `make install-unsigned` builds with ad-hoc signing.

### CI/CD signing

GitHub Actions handles signing and notarization automatically on tag push. The workflow:

1. Imports the Developer ID certificate from `DEVELOPER_ID_CERT_BASE64` secret
2. Signs with `codesign --options runtime` (hardened runtime required for notarization)
3. Submits to Apple via `xcrun notarytool` using the App Store Connect API key
4. Staples the notarization ticket with `xcrun stapler`
5. Creates a GitHub Release with the signed `.app` zip attached

### GitHub Secrets (stored in repo settings)

| Secret | Purpose |
|--------|---------|
| `DEVELOPER_ID_CERT_BASE64` | Base64-encoded `.p12` certificate export |
| `DEVELOPER_ID_CERT_PASSWORD` | Password for the `.p12` file |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `NOTARY_KEY_ID` | App Store Connect API Key ID |
| `NOTARY_ISSUER_ID` | App Store Connect API Issuer ID |
| `NOTARY_KEY_BASE64` | Base64-encoded `.p8` API key |

### Sensitive files (never committed)

The `.gitignore` excludes these files:
- `.env` — local environment variables (key IDs, passwords)
- `*.p12` — certificate exports
- `*.p8` — App Store Connect API keys
- `*.certSigningRequest` — certificate signing requests

## CI/CD Workflows

### `.github/workflows/build.yml`
- **Triggers:** Push to `master`, pull requests
- **Purpose:** Verifies the project compiles on macOS
- **Steps:** Checkout → `make build` → verify bundle

### `.github/workflows/release.yml`
- **Triggers:** Push of a tag matching `v*.*.*`
- **Security:** Only runs on `webdz9r/opencode-menubar` (not forks)
- **Purpose:** Build, sign, notarize, and publish a GitHub Release
- **Steps:** Import cert → build → sign → notarize → zip → create release → cleanup

## Adding New Features

### Adding a menu item
1. Add an `NSMenuItem` property in `AppDelegate` if it needs dynamic updates
2. Create the item in `buildMenu()` with an `action` selector and `target = self`
3. Add the `@objc` action method in the Actions section
4. Update `updateMenuState()` if the item's enabled/title state depends on server state

### Adding server command options
1. Modify `proc.arguments` in `ServerManager.start()` to add CLI flags
2. If the option should be user-configurable, add a menu toggle in `AppDelegate` and store the preference with `UserDefaults`

### Adding a new server state
1. Add the case to `ServerState` enum and its `description`
2. Update the icon switch in `AppDelegate.updateMenuState()` to handle the new state
3. Update the color logic in `updateIcon(running:)` if the new state needs a distinct icon color
4. Add transitions in `ServerManager` that enter/exit the new state

### Bumping the version / creating a release
1. Update `AppDelegate.appVersion` in `Sources/AppDelegate.swift`
2. Update `CFBundleShortVersionString` in `Resources/Info.plist`
3. Add an entry in `CHANGELOG.md`
4. Commit and push to `master`
5. Create and push a git tag: `git tag v1.2.3 && git push origin v1.2.3`
6. GitHub Actions will automatically build, sign, notarize, and publish the release

### Persisting user preferences
Use `UserDefaults.standard` with keys prefixed by the bundle ID. Example:
```swift
UserDefaults.standard.bool(forKey: "com.opencode.taskbar.somePreference")
```

## Conventions

- All UI updates must happen on the main thread (state changes in `ServerManager` dispatch delegate calls via `DispatchQueue.main.async`)
- Use `NSLog` for logging — it writes to Console.app and is visible with `log stream --predicate 'process == "OpenCodeMenuBar"'`
- The `@objc` attribute is required on all menu action methods
- Keep `main.swift` minimal — it should only bootstrap the app
- The `.gitignore` excludes `build/`, `.env`, `*.p12`, `*.p8` — never commit build artifacts or secrets
- The menubar icon must use `image.isTemplate = false` to preserve custom colors

## Debugging

View live logs:
```bash
log stream --predicate 'process == "OpenCodeMenuBar"' --level debug
```

Check if the server process is running:
```bash
pgrep -fl opencode
```

Check if the app is running:
```bash
pgrep -fl OpenCodeMenuBar.app
```

Force quit (if needed):
```bash
pkill -f "OpenCodeMenuBar.app/Contents/MacOS/OpenCodeMenuBar"
```

Verify code signature:
```bash
codesign --verify --deep --strict --verbose=2 build/OpenCodeMenuBar.app
```

Verify notarization:
```bash
spctl --assess --type execute --verbose=2 build/OpenCodeMenuBar.app
```
