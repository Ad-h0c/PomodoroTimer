# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development

This is a native macOS SwiftUI app built with Xcode. No package manager (npm, CocoaPods, SPM) is used.

```bash
# Build from command line
xcodebuild -scheme PomodoroTimer -configuration Debug build

# Build release
xcodebuild -scheme PomodoroTimer -configuration Release build

# Clean build
xcodebuild -scheme PomodoroTimer clean
```

For development, open `PomodoroTimer.xcodeproj` in Xcode and use Cmd+R to build and run.

**Target platform**: macOS 14+

## Architecture

Menu bar app using SwiftUI's `MenuBarExtra` with MVVM pattern:

- **Entry point**: `PomodoroTimer/PomodoroTimerApp.swift` - Uses `@main` with `MenuBarExtra` for menu bar integration
- **Main model**: `PomodoroTimer/Models/PomodoroTimer.swift` - `PomodoroTimerModel` (ObservableObject) handles timer state, phases, and todo CRUD operations
- **Views**: `PomodoroTimer/Views/ContentView.swift` (main popover) and `SettingsView.swift` (settings window with tabs)
- **Keyboard shortcuts**: `PomodoroTimer/KeyboardShortcutManager.swift` - Global hotkey handling via NSEvent monitoring

### State Management

- `PomodoroTimerModel` is the single source of truth, injected as `@EnvironmentObject`
- Timer settings use `@AppStorage` for UserDefaults persistence
- Todos are JSON-encoded and stored in UserDefaults under key `"todos"`

### Key Patterns

- Settings window uses a singleton `SettingsWindowController` for reliable window management
- Keyboard shortcuts require Accessibility permissions for global monitoring; falls back to local monitoring without them
- Todo items track both creation and completion timestamps for history feature

## Permissions

The app requires:
1. **Notifications** - Requested on first launch for timer alerts
2. **Accessibility** - Required for global keyboard shortcuts to work outside the popover

## Data Storage

All data persists in UserDefaults at:
```
~/Library/Containers/com.yourcompany.PomodoroTimer/Data/Library/Preferences/
```

No external databases or cloud services.
