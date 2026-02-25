# Features

Tracking sheet for all current and planned features in opencode-menubar.

## Status Legend

| Status | Meaning |
|--------|---------|
| Done | Shipped and working |
| In Progress | Currently being implemented |
| Planned | Accepted, not yet started |
| Idea | Under consideration |

---

## Core

| Feature | Status | Description |
|---------|--------|-------------|
| Menubar icon | Done | Custom-drawn circle with "OC" text; adapts to light/dark mode automatically |
| Dropdown menu | Done | Click icon to reveal status, actions, and settings |
| No dock icon | Done | App is `LSUIElement` — runs entirely in the menubar with no dock presence |
| Dark mode support | Done | Icon background and text colors invert based on system appearance |

## Server Management

| Feature | Status | Description |
|---------|--------|-------------|
| Start server | Done | Spawns `opencode web --mdns` as a child process |
| Stop server | Done | Graceful shutdown: SIGTERM, then SIGINT after 5s, then SIGKILL after 7s |
| Status display | Done | Menu shows current state with icon: `●` running, `○` stopped, `◐` starting, `◑` stopping |
| Crash recovery | Done | Detects unexpected process termination and resets UI to stopped state |
| Binary detection | Done | Checks `/opt/homebrew/bin/opencode` then `/usr/local/bin/opencode`; shows error if not found |
| Cleanup on quit | Done | Stops the server process before the app exits |

## System Integration

| Feature | Status | Description |
|---------|--------|-------------|
| Launch at Login | Done | Toggle in menu to register/unregister as a macOS Login Item via `SMAppService` |
| Keyboard shortcuts | Done | `Cmd+S` to start, `Cmd+X` to stop, `Cmd+Q` to quit |
| Version display | Done | Shows current version at bottom of menu; clicks through to GitHub releases page |

## Distribution

| Feature | Status | Description |
|---------|--------|-------------|
| Developer ID code signing | Done | Signed with `Developer ID Application` certificate and hardened runtime |
| Apple notarization | Done | Submitted to Apple for notarization; ticket stapled to `.app` bundle |
| CI build verification | Done | GitHub Actions verifies compilation on every push and PR |
| Automated releases | Done | Pushing a `v*.*.*` tag triggers build, sign, notarize, and GitHub Release |
| Pre-built download | Done | Signed `.app` zip attached to each GitHub Release |

## Planned / Ideas

| Feature | Status | Description |
|---------|--------|-------------|
| Auto-start server on launch | Idea | Optionally start the server automatically when the app opens |
| Custom port configuration | Idea | Allow setting the `--port` flag from the menu |
| Custom mDNS domain | Idea | Allow setting `--mdns-domain` from the menu |
| Server output log viewer | Idea | Show recent stdout/stderr output in a window or submenu |
| Update notifications | Idea | Detect when a new version of opencode is available |
| Open in browser | Idea | Menu item to open the opencode web UI in the default browser |
