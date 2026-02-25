# opencode-menubar

A native macOS menubar app to start and stop the [opencode](https://github.com/anomalyco/opencode) web server with mDNS discovery.

Lives in your menubar. No dock icon. No window. Click to start, click to stop.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![Architecture](https://img.shields.io/badge/arch-arm64-lightgrey) [![Build](https://github.com/webdz9r/opencode-menubar/actions/workflows/build.yml/badge.svg)](https://github.com/webdz9r/opencode-menubar/actions/workflows/build.yml)

> **Disclaimer:** This project is not built by, maintained by, or affiliated with the [OpenCode](https://opencode.ai) team. It is an independent community project that integrates with the `opencode` CLI tool.

## Download

**Pre-built, signed, and notarized** — download the latest release:

> [**Download OpenCodeMenuBar.app**](https://github.com/webdz9r/opencode-menubar/releases/latest)

Unzip and drag to your Applications folder. The app is signed with a Developer ID certificate and notarized by Apple, so it opens without Gatekeeper warnings.

## What it does

- Runs `opencode web --mdns` as a managed child process
- Custom menubar icon: circle with **OC** text that changes color with server state
- Adapts to light and dark mode automatically
- Graceful shutdown with escalating signals (SIGTERM -> SIGINT -> SIGKILL)
- Detects crashes and resets automatically
- Optionally starts at login
- Version number in menu links to [GitHub releases](https://github.com/webdz9r/opencode-menubar/releases)

## Menubar Icon

The icon is a circle with "OC" rendered inside it. The colors adapt based on server state and system appearance:

| State | Light Mode | Dark Mode |
|-------|-----------|-----------|
| **Stopped** | Black circle, white text | White circle, black text |
| **Running** | Black circle, green text | White circle, green text |

## About OpenCode

[OpenCode](https://opencode.ai) is an open-source CLI tool for coding with LLMs from the terminal. This menubar app manages the `opencode web --mdns` server, which provides browser access and mDNS discovery for OpenCode.

Install OpenCode using one of these methods:

```bash
# Homebrew
brew install anomalyco/tap/opencode

# npm
npm install -g opencode

# Shell script
curl -fsSL https://opencode.ai/install | bash
```

For more information, see the [OpenCode repository](https://github.com/anomalyco/opencode) and [opencode.ai](https://opencode.ai).

## Requirements

- macOS 13.0 or later (Apple Silicon)
- [opencode](https://github.com/anomalyco/opencode) installed via one of the methods above

### Build from source (additional requirements)

- Xcode Command Line Tools (`xcode-select --install`)

## Install from Source

```bash
git clone git@github.com:webdz9r/opencode-menubar.git
cd opencode-menubar
make install-unsigned
```

This compiles the app with ad-hoc signing, copies it to `~/Applications/`, and launches it.

If you have the Developer ID certificate installed locally, you can build a fully signed and notarized version:

```bash
make install
```

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Compile and create `.app` bundle in `build/` (ad-hoc signed) |
| `make sign` | Re-sign with Developer ID + hardened runtime |
| `make notarize` | Submit to Apple for notarization and staple the ticket |
| `make release` | Full pipeline: build + sign + notarize |
| `make install` | Release pipeline + install to `~/Applications/` |
| `make install-unsigned` | Build + install without Developer ID (for contributors) |
| `make uninstall` | Stop the app and remove from `~/Applications/` |
| `make run` | Build and run from `build/` without installing |
| `make clean` | Remove `build/` directory |

## Usage

Click the menubar icon to open the dropdown:

| Menu Item | Description |
|-----------|-------------|
| **Status** | Shows current server state (`●` running, `○` stopped, `◐` starting, `◑` stopping) |
| **Start Server** (`Cmd+S`) | Launches `opencode web --mdns` |
| **Stop Server** (`Cmd+X`) | Gracefully stops the server |
| **Launch at Login** | Toggle auto-start when you log in |
| **Quit OpenCode Menubar** (`Cmd+Q`) | Stops the server and exits the app |
| **v1.0.0** | Current version — click to view releases on GitHub |

## Project Structure

```
opencode-menubar/
├── Sources/
│   ├── main.swift              # App entry point (minimal bootstrap)
│   ├── AppDelegate.swift       # Menubar UI, icon rendering, menu actions
│   └── ServerManager.swift     # Process lifecycle, state machine
├── Resources/
│   └── Info.plist              # Bundle config (LSUIElement, etc.)
├── .github/workflows/
│   ├── build.yml               # CI: verify compilation on push/PR
│   └── release.yml             # CD: sign, notarize, publish on tag push
├── docs/
│   └── features.md             # Feature tracking and roadmap
├── AGENTS.md                   # Codebase guide for AI agents / maintainers
├── CHANGELOG.md                # Release history
├── LICENSE                     # MIT License
└── Makefile                    # Build, sign, notarize, install targets
```

## How it works

The app is built with pure AppKit (no SwiftUI, no Xcode project). It compiles with `swiftc` and the Makefile assembles the `.app` bundle manually.

**ServerManager** owns the `opencode` child process. It resolves the binary path at init, spawns it with `Foundation.Process`, and monitors it via a termination handler. State changes (`stopped` / `starting` / `running` / `stopping`) are dispatched to the main thread where **AppDelegate** updates the menu and icon.

**The menubar icon** is drawn programmatically using `NSImage` with `NSBezierPath` (circle) and `NSAttributedString` (text). It uses `NSAppearance.currentDrawing()` to detect light/dark mode at render time, so the icon always contrasts properly with the menubar background.

Shutdown is escalating: SIGTERM first, SIGINT after 5 seconds, SIGKILL after 7 seconds. On app quit, the server is stopped synchronously before exit.

## Releases

Releases are built, signed, and notarized automatically via GitHub Actions when a version tag is pushed. The signed `.app` is attached to each [GitHub Release](https://github.com/webdz9r/opencode-menubar/releases).

## Debugging

```bash
# Watch app logs
log stream --predicate 'process == "OpenCodeMenuBar"' --level debug

# Check if opencode server is running
pgrep -fl opencode

# Force quit the menubar app
pkill -f "OpenCodeMenuBar.app/Contents/MacOS/OpenCodeMenuBar"

# Verify code signature
codesign --verify --deep --strict --verbose=2 build/OpenCodeMenuBar.app
```

## Contributing

See [AGENTS.md](AGENTS.md) for a detailed walkthrough of the codebase architecture, conventions, and how to add features.

See [docs/features.md](docs/features.md) for the current feature status and roadmap.

## License

[MIT](LICENSE)
