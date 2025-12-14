import SwiftUI
import AppKit

class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()

    struct Shortcut: Codable, Equatable {
        var key: String
        var keyCode: UInt16?
        var command: Bool
        var option: Bool
        var control: Bool
        var shift: Bool
        var function: Bool

        init(key: String, keyCode: UInt16? = nil, command: Bool = false, option: Bool = false, control: Bool = false, shift: Bool = false, function: Bool = false) {
            self.key = key
            self.keyCode = keyCode
            self.command = command
            self.option = option
            self.control = control
            self.shift = shift
            self.function = function
        }

        init?(event: NSEvent) {
            let keyInfo = Shortcut.extractKeyInfo(from: event)
            let flags = event.modifierFlags
            self.key = keyInfo.key.lowercased()
            self.keyCode = keyInfo.keyCode
            self.command = flags.contains(.command)
            self.option = flags.contains(.option)
            self.control = flags.contains(.control)
            self.shift = flags.contains(.shift)
            self.function = flags.contains(.function)
        }

        var modifierFlags: NSEvent.ModifierFlags {
            var flags: NSEvent.ModifierFlags = []
            if command { flags.insert(.command) }
            if option { flags.insert(.option) }
            if control { flags.insert(.control) }
            if shift { flags.insert(.shift) }
            if function { flags.insert(.function) }
            return flags
        }

        var displayString: String {
            var parts: [String] = []
            if function { parts.append("fn") }
            if control { parts.append("^") }
            if option { parts.append("⌥") }
            if shift { parts.append("⇧") }
            if command { parts.append("⌘") }

            let keyDisplay = Shortcut.displayKey(for: key, keyCode: keyCode)
            parts.append(keyDisplay)

            return parts.joined(separator: " ")
        }
        static let defaultStartPause = Shortcut(key: "↩", keyCode: 36, command: true, option: true)
        static let defaultReset = Shortcut(key: "r", keyCode: 15, command: true, option: true)
        static let defaultSkip = Shortcut(key: "s", keyCode: 3, command: true, option: true)

        private static func extractKeyInfo(from event: NSEvent) -> (key: String, keyCode: UInt16) {
            if let characters = event.charactersIgnoringModifiers, !characters.isEmpty {
                return (characters, event.keyCode)
            }
            return ("", event.keyCode)
        }

        private static func displayKey(for key: String, keyCode: UInt16?) -> String {
            if let code = keyCode, let special = specialKeySymbol(for: code) {
                return special
            }

            let trimmed = key.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty && keyCode == 49 { // space key code
                return "Space"
            }

            if trimmed.lowercased() == " " {
                return "Space"
            }

            if trimmed.uppercased().hasPrefix("F"), let number = Int(trimmed.dropFirst()) {
                return "F\(number)"
            }

            return trimmed.uppercased()
        }

        private static func specialKeySymbol(for keyCode: UInt16) -> String? {
            switch keyCode {
            case 36: return "↩" // return
            case 76: return "⌤" // enter
            case 51: return "⌫" // delete
            case 117: return "⌦" // forward delete
            case 53: return "⎋" // escape
            case 48: return "⇥" // tab
            case 49: return "Space"
            case 123: return "←"
            case 124: return "→"
            case 125: return "↓"
            case 126: return "↑"
            case 115: return "↖" // home
            case 119: return "↘" // end
            case 116: return "⇞" // page up
            case 121: return "⇟" // page down
            default:
                return nil
            }
        }
    }

    weak var pomodoroTimer: PomodoroTimerModel?
    @Published var isEditingShortcut = false
    private var localMonitor: Any?
    private var globalMonitor: Any?

    @Published var startPauseShortcut: Shortcut {
        didSet { saveShortcut(startPauseShortcut, forKey: startPauseKey) }
    }
    @Published var resetShortcut: Shortcut {
        didSet { saveShortcut(resetShortcut, forKey: resetKey) }
    }
    @Published var skipShortcut: Shortcut {
        didSet { saveShortcut(skipShortcut, forKey: skipKey) }
    }

    private let defaults = UserDefaults.standard
    private let startPauseKey = "shortcut_startPause_v2"
    private let resetKey = "shortcut_reset_v2"
    private let skipKey = "shortcut_skip_v2"
    private let legacyStartPauseKey = "shortcut_startPause"
    private let legacyResetKey = "shortcut_reset"
    private let legacySkipKey = "shortcut_skip"

    init() {
        startPauseShortcut = Self.loadShortcut(
            from: defaults,
            newKey: startPauseKey,
            legacyKey: legacyStartPauseKey,
            fallback: .defaultStartPause
        )
        resetShortcut = Self.loadShortcut(
            from: defaults,
            newKey: resetKey,
            legacyKey: legacyResetKey,
            fallback: .defaultReset
        )
        skipShortcut = Self.loadShortcut(
            from: defaults,
            newKey: skipKey,
            legacyKey: legacySkipKey,
            fallback: .defaultSkip
        )

        // Check accessibility permissions before setting up global shortcuts
        checkAccessibilityPermissions()
        setupKeyboardMonitoring()
    }

    @Published var needsAccessibilityPermission = false

    private func checkAccessibilityPermissions() {
        // Don't prompt immediately - just check
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            needsAccessibilityPermission = true
            print("⚠️ Accessibility permissions not granted. Global shortcuts will not work.")
        } else {
            needsAccessibilityPermission = false
        }
    }

    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    deinit {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupKeyboardMonitoring() {
        // Always set up local monitor
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handleLocal(event: event)
        }

        // Only set up global monitor if we have accessibility permissions
        // This prevents timeout errors
        if AXIsProcessTrusted() {
            setupGlobalMonitor()
        } else {
            print("⚠️ Skipping global shortcuts - accessibility permission not granted")
        }
    }

    func setupGlobalMonitor() {
        // Remove existing monitor if any
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // Global monitor - works system-wide even when app doesn't have focus
        // Only process events that could potentially be our shortcuts
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            // Quick pre-filter: only process if event matches our shortcut keys
            if self.couldBeShortcut(event) {
                self.handleGlobal(event: event)
            }
        }

        needsAccessibilityPermission = false
        print("✅ Global shortcuts enabled")
    }

    private func couldBeShortcut(_ event: NSEvent) -> Bool {
        // Skip if editing shortcuts
        if isEditingShortcut {
            return false
        }

        // Check if the keyCode matches any of our shortcuts
        let keyCode = event.keyCode
        return keyCode == startPauseShortcut.keyCode ||
               keyCode == resetShortcut.keyCode ||
               keyCode == skipShortcut.keyCode
    }

    private func handleLocal(event: NSEvent) -> NSEvent? {
        let handled = handleShortcut(event: event)
        return handled ? nil : event
    }

    private func handleGlobal(event: NSEvent) {
        _ = handleShortcut(event: event)
    }

    private func handleShortcut(event: NSEvent) -> Bool {
        // Skip shortcut handling while the user is editing a shortcut
        if isEditingShortcut {
            return false
        }

        guard let key = event.charactersIgnoringModifiers?.lowercased(), !key.isEmpty else {
            return false
        }

        // Handle shortcuts asynchronously to prevent blocking
        if matches(event, shortcut: resetShortcut) {
            DispatchQueue.main.async { [weak self] in
                self?.pomodoroTimer?.resetTimer()
            }
            return true
        }

        if matches(event, shortcut: skipShortcut) {
            DispatchQueue.main.async { [weak self] in
                self?.pomodoroTimer?.skipPhase()
            }
            return true
        }

        if matches(event, shortcut: startPauseShortcut) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let timer = self.pomodoroTimer else { return }
                if timer.isRunning {
                    timer.pauseTimer()
                } else {
                    timer.startTimer()
                }
            }
            return true
        }

        return false
    }

    private func matches(_ event: NSEvent, shortcut: Shortcut) -> Bool {
        // Key match using keyCode first for special keys
        if let code = shortcut.keyCode, code != event.keyCode {
            return false
        }

        if shortcut.keyCode == nil {
            guard let eventKey = event.charactersIgnoringModifiers?.lowercased(),
                  eventKey == shortcut.key.lowercased() else {
                return false
            }
        }

        let allowedFlags: NSEvent.ModifierFlags = [.command, .option, .control, .shift, .function]
        let relevantFlags = event.modifierFlags.intersection(allowedFlags)
        let shortcutFlags = shortcut.modifierFlags.intersection(allowedFlags)
        return relevantFlags == shortcutFlags
    }

    private func saveShortcut(_ shortcut: Shortcut, forKey key: String) {
        if let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadShortcut(from defaults: UserDefaults, newKey: String, legacyKey: String, fallback: Shortcut) -> Shortcut {
        if let data = defaults.data(forKey: newKey),
           let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) {
            return shortcut
        }

        if let legacyValue = defaults.string(forKey: legacyKey), !legacyValue.isEmpty {
            var legacyShortcut = fallback
            legacyShortcut.key = legacyValue
            return legacyShortcut
        }

        return fallback
    }
}
