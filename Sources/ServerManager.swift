import Foundation

protocol ServerManagerDelegate: AnyObject {
    func serverDidChangeState(_ manager: ServerManager)
}

enum ServerState {
    case stopped
    case starting
    case running
    case stopping

    var description: String {
        switch self {
        case .stopped:  return "Stopped"
        case .starting: return "Starting..."
        case .running:  return "Running"
        case .stopping: return "Stopping..."
        }
    }
}

class ServerManager {
    weak var delegate: ServerManagerDelegate?

    private(set) var state: ServerState = .stopped {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.serverDidChangeState(self)
            }
        }
    }

    private var process: Process?
    private var outputPipe: Pipe?
    private let opencodePath: String

    var binaryFound: Bool {
        return FileManager.default.fileExists(atPath: opencodePath)
    }

    init() {
        // Resolve opencode binary path
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/opencode") {
            self.opencodePath = "/opt/homebrew/bin/opencode"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/opencode") {
            self.opencodePath = "/usr/local/bin/opencode"
        } else {
            self.opencodePath = "/opt/homebrew/bin/opencode"
        }
    }

    var isRunning: Bool {
        return state == .running || state == .starting
    }

    func start() {
        guard state == .stopped else { return }

        guard binaryFound else {
            NSLog("OpenCode binary not found at: \(opencodePath)")
            return
        }

        state = .starting

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: opencodePath)
        proc.arguments = ["web", "--mdns"]

        // Inherit environment so node/opencode can find dependencies
        var env = ProcessInfo.processInfo.environment
        if let path = env["PATH"] {
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + path
        }
        proc.environment = env

        // Capture output for debugging
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        self.outputPipe = pipe

        proc.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            if self.state != .stopping {
                NSLog("OpenCode server terminated unexpectedly (exit: \(process.terminationStatus))")
            }
            self.state = .stopped
            self.process = nil
            self.outputPipe = nil
        }

        do {
            try proc.run()
            self.process = proc
            self.state = .running
            NSLog("OpenCode server started (PID: \(proc.processIdentifier))")
        } catch {
            NSLog("Failed to start OpenCode server: \(error.localizedDescription)")
            self.state = .stopped
        }
    }

    func stop() {
        guard let proc = process, proc.isRunning else {
            state = .stopped
            return
        }

        state = .stopping
        NSLog("Stopping OpenCode server (PID: \(proc.processIdentifier))")

        // Send SIGTERM for graceful shutdown
        proc.terminate()

        // Force kill after 5 seconds if still running
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, let proc = self.process, proc.isRunning else { return }
            NSLog("Force killing OpenCode server (PID: \(proc.processIdentifier))")
            proc.interrupt()
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                if proc.isRunning {
                    kill(proc.processIdentifier, SIGKILL)
                }
            }
        }
    }

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    /// Clean up on app termination
    func cleanup() {
        if let proc = process, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
    }
}
