import SwiftUI
import AppKit

enum SettingsTab: String {
    case timer, history, shortcuts, general, about
}

extension Notification.Name {
    static let showSettingsTab = Notification.Name("showSettingsTab")
}

class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var settingsWindow: NSWindow?

    func showSettings(timer: PomodoroTimerModel, tab: SettingsTab? = nil) {
        if settingsWindow == nil {
            createWindow(timer: timer, initialTab: tab)
        } else if let tab {
            NotificationCenter.default.post(name: .showSettingsTab, object: nil, userInfo: ["tab": tab.rawValue])
        }

        guard let window = settingsWindow else { return }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow(timer: PomodoroTimerModel, initialTab: SettingsTab?) {
        let settingsView = SettingsView(initialTab: initialTab)
            .environmentObject(timer)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 400))
        window.center()
        window.isReleasedWhenClosed = false

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.settingsWindow = nil
        }

        settingsWindow = window

        if let tab = initialTab {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showSettingsTab, object: nil, userInfo: ["tab": tab.rawValue])
            }
        }
    }
}

@main
struct PomodoroTimerApp: App {
    @StateObject private var pomodoroTimer: PomodoroTimerModel

    init() {
        let timer = PomodoroTimerModel()
        _pomodoroTimer = StateObject(wrappedValue: timer)
        KeyboardShortcutManager.shared.pomodoroTimer = timer
        FloatingTaskInputController.shared.timer = timer
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(pomodoroTimer)
                .environment(\.openSettings, OpenSettingsAction {
                    SettingsWindowController.shared.showSettings(timer: pomodoroTimer)
                })
        } label: {
            Image(systemName: pomodoroTimer.isRunning ? "timer" : "timer.circle")
            if pomodoroTimer.isRunning {
                Text(pomodoroTimer.timeString)
                    .monospacedDigit()
                .font(.system(size: 12))
            }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsWindowController.shared.showSettings(timer: pomodoroTimer)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Replace Help menu to show About panel
            CommandGroup(replacing: .help) {
                Button("About PomodoroTimer") {
                    SettingsWindowController.shared.showSettings(timer: pomodoroTimer, tab: .about)
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
            }
        }
    }
}

struct OpenSettingsAction {
    let action: () -> Void

    func callAsFunction() {
        action()
    }
}

private struct OpenSettingsKey: EnvironmentKey {
    static let defaultValue = OpenSettingsAction(action: {})
}

extension EnvironmentValues {
    var openSettings: OpenSettingsAction {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
}
