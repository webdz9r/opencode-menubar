import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    static let appVersion = "1.0.1"
    static let releasesURL = "https://github.com/webdz9r/opencode-menubar/releases"

    private var statusItem: NSStatusItem!
    private let serverManager = ServerManager()

    // Menu items that need dynamic updates
    private var statusMenuItem: NSMenuItem!
    private var startMenuItem: NSMenuItem!
    private var stopMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        serverManager.delegate = self

        setupStatusItem()
        buildMenu()
        updateMenuState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        serverManager.cleanup()
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateIcon(running: false)
            button.toolTip = "OpenCode Menubar"
        }
    }

    private func updateIcon(running: Bool) {
        guard let button = statusItem.button else { return }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Detect dark/light appearance
            let isDark = NSAppearance.currentDrawing().bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            // Circle background adapts to appearance:
            // Light menubar -> dark circle, dark menubar -> light circle
            let bgColor: NSColor = isDark ? .white : .black
            bgColor.setFill()
            let circlePath = NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5))
            circlePath.fill()

            // "OC" text: green when running, contrast color when stopped
            let textColor: NSColor
            if running {
                textColor = NSColor.systemGreen
            } else {
                textColor = isDark ? .black : .white
            }
            let font = NSFont.systemFont(ofSize: 8.5, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let text = "OC" as NSString
            let textSize = text.size(withAttributes: attrs)
            let textRect = NSRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)

            return true
        }

        image.isTemplate = false
        button.image = image
        button.title = ""
    }

    // MARK: - Menu Construction

    private func buildMenu() {
        let menu = NSMenu()

        // Status line
        statusMenuItem = NSMenuItem(title: "Status: Stopped", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Start
        startMenuItem = NSMenuItem(title: "Start Server", action: #selector(startServer), keyEquivalent: "s")
        startMenuItem.target = self
        menu.addItem(startMenuItem)

        // Stop
        stopMenuItem = NSMenuItem(title: "Stop Server", action: #selector(stopServer), keyEquivalent: "x")
        stopMenuItem.target = self
        menu.addItem(stopMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login
        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit OpenCode Menubar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.addItem(NSMenuItem.separator())

        // Version (links to changelog)
        let versionItem = NSMenuItem(title: "v\(AppDelegate.appVersion)", action: #selector(openReleases), keyEquivalent: "")
        versionItem.target = self
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        versionItem.attributedTitle = NSAttributedString(string: "v\(AppDelegate.appVersion)", attributes: attributes)
        menu.addItem(versionItem)

        statusItem.menu = menu
    }

    private func updateMenuState() {
        let running = serverManager.isRunning
        let state = serverManager.state

        // Update status text
        if !serverManager.binaryFound {
            statusMenuItem.title = "Error: opencode not found"
        } else {
            let icon: String
            switch state {
            case .running:  icon = "●"
            case .starting: icon = "◐"
            case .stopping: icon = "◑"
            case .stopped:  icon = "○"
            }
            statusMenuItem.title = "\(icon)  Server: \(state.description)"
        }

        // Enable/disable actions
        startMenuItem.isEnabled = (state == .stopped) && serverManager.binaryFound
        stopMenuItem.isEnabled = running

        // Update icon color
        updateIcon(running: running)
    }

    // MARK: - Actions

    @objc private func startServer() {
        serverManager.start()
    }

    @objc private func stopServer() {
        serverManager.stop()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp

        do {
            if isLaunchAtLoginEnabled() {
                try service.unregister()
                launchAtLoginMenuItem.state = .off
                NSLog("Unregistered from Login Items")
            } else {
                try service.register()
                launchAtLoginMenuItem.state = .on
                NSLog("Registered as Login Item")
            }
        } catch {
            NSLog("Failed to toggle Login Item: \(error.localizedDescription)")
            // Show alert
            let alert = NSAlert()
            alert.messageText = "Login Item Error"
            alert.informativeText = "Could not update login item setting: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    @objc private func openReleases() {
        if let url = URL(string: AppDelegate.releasesURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp() {
        serverManager.cleanup()
        NSApp.terminate(nil)
    }
}

// MARK: - ServerManagerDelegate

extension AppDelegate: ServerManagerDelegate {
    func serverDidChangeState(_ manager: ServerManager) {
        updateMenuState()
    }
}
