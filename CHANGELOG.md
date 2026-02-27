# Changelog

All notable changes to opencode-menubar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-02-26

### Fixed
- Set server working directory to `/tmp` instead of `/`, preventing macOS TCC permission prompts for protected directories

## [1.0.0] - 2025-02-25

### Added
- Menubar icon with server status indicator (green = running, gray = stopped)
- Start/stop server via dropdown menu
- Graceful shutdown with escalating signals (SIGTERM -> SIGINT -> SIGKILL)
- Automatic crash detection and UI reset
- Launch at Login toggle via macOS Login Items
- Keyboard shortcuts: Cmd+S (start), Cmd+X (stop), Cmd+Q (quit)
- Version number in menu footer linking to this changelog
- Binary auto-detection (`/opt/homebrew/bin/opencode`, `/usr/local/bin/opencode`)

[1.0.1]: https://github.com/webdz9r/opencode-menubar/releases/tag/v1.0.1
[1.0.0]: https://github.com/webdz9r/opencode-menubar/releases/tag/v1.0.0
