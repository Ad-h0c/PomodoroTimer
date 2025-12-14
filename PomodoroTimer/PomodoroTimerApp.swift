import SwiftUI
import AppKit

class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var settingsWindow: NSWindow?

    func showSettings(timer: PomodoroTimerModel) {
        if settingsWindow == nil {
            createWindow(timer: timer)
        }

        guard let window = settingsWindow else { return }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        // Just bring window to front - no explicit app activation needed for MenuBarExtra
        window.makeKeyAndOrderFront(nil)
    }

    private func createWindow(timer: PomodoroTimerModel) {
        let settingsView = SettingsView()
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
    }
}

@main
struct PomodoroTimerApp: App {
    @StateObject private var pomodoroTimer: PomodoroTimerModel

    init() {
        let timer = PomodoroTimerModel()
        _pomodoroTimer = StateObject(wrappedValue: timer)
        KeyboardShortcutManager.shared.pomodoroTimer = timer
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
                    NSApp.orderFrontStandardAboutPanel(nil)
                    NSApp.activate(ignoringOtherApps: true)
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
