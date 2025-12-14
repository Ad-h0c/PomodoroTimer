import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    init() {
        setupKeyboardShortcuts()
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
                if event.charactersIgnoringModifiers == "," {
                    self.openSettings()
                    return nil
                }
            }
            return event
        }
    }

    private func openSettings() {
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
