# Pomodoro Timer - macOS Menu Bar App

A native macOS Pomodoro timer application with integrated todo list that lives in your menu bar. Built with Swift and SwiftUI for macOS 14+.

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar, always accessible
- **Pomodoro Timer**: Classic 25-minute focus sessions with breaks
- **Todo List**: Full task management
  - Add tasks with the plus button or Enter key
  - Edit tasks by double-clicking or using the edit button
  - Delete tasks with the trash button (appears on hover)
  - Mark tasks as complete/incomplete
- **Customizable Durations**: Adjust focus time, short breaks, and long breaks
- **Notifications**: Get notified when sessions complete
- **Auto-start Options**: Automatically transition between work and breaks
- **Data Persistence**: Your todos and settings are saved automatically
- **Keyboard Shortcuts**:
  - `⌘⌥↩︎` (Command + Return) - Start / Pause Timer
  - `⌘⌥R` - Reset Timer
  - `⌘⌥S` - Skip Phase
  - `⌘,` - Open Settings
  - `⌘Q` - Quit Application
- **Task History**: View completed tasks organized by date with completion timestamps

## Project Structure

```
PomodoroTimer/
├── PomodoroTimerApp.swift         # Main app entry point
├── MenuBarManager.swift           # Menu bar setup (legacy)
├── KeyboardShortcutManager.swift  # Keyboard shortcut handling
├── Models/
│   ├── PomodoroTimer.swift        # Timer logic and state management
│   └── TodoItem.swift             # Todo data model
├── Views/
│   ├── ContentView.swift          # Main popover UI with timer and todos
│   └── SettingsView.swift         # Settings window with tabs
├── Assets.xcassets/               # App icons and resources
├── Info.plist                     # App configuration
└── PomodoroTimer.entitlements     # Sandboxing permissions
```

## How to Build and Run

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later

### Steps

1. **Open the Project**

   - Navigate to the `PomodoroTimer` folder
   - Double-click `PomodoroTimer.xcodeproj` to open in Xcode

2. **Build the App**

   - Select the "PomodoroTimer" scheme in Xcode
   - Choose "My Mac" as the destination
   - Press `⌘B` to build or `⌘R` to run

3. **Grant Permissions**
   - On first launch, the app will request notification permissions
   - Click "Allow" to receive timer completion notifications

## Using the App

### Managing Tasks

1. **Adding Tasks**

   - Type your task in the text field at the bottom
   - Press Enter or click the plus button to add

2. **Editing Tasks**

   - Double-click any task to edit it inline
   - Or hover over a task and click the pencil icon
   - Press Enter to save changes

3. **Completing Tasks**

   - Click the circle icon next to a task to mark it complete
   - Click again to mark it incomplete

4. **Deleting Tasks**
   - Hover over a task to reveal the trash button
   - Click the trash icon to delete

### Viewing Task History

1. Open Settings (`⌘,`)
2. Go to the "History" tab
3. See all your completed tasks organized by date
4. Each task shows the time it was completed

Completed tasks remain in your history until you delete them from the main task list.

## Understanding the Code

### Swift Basics for Beginners

#### 1. **PomodoroTimerApp.swift** - App Entry Point

```swift
@main  // This marks the app's entry point
struct PomodoroTimerApp: App {
    @StateObject private var pomodoroTimer = PomodoroTimerModel()
    // @StateObject creates and owns an observable object
}
```

#### 2. **PomodoroTimer.swift** - Core Logic

```swift
class PomodoroTimerModel: ObservableObject {
    @Published var timeRemaining: TimeInterval
    // @Published automatically updates UI when value changes

    @AppStorage("workDuration") var workDuration: Double = 25
    // @AppStorage saves to UserDefaults automatically
}
```

#### 3. **ContentView.swift** - Main UI

```swift
struct ContentView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    // @EnvironmentObject receives shared data from parent

    var body: some View {
        VStack {  // Vertical stack of views
            // UI components
        }
    }
}
```

### Key Concepts

**SwiftUI**: Declarative UI framework - you describe what you want, not how to build it

**@Published**: Marks properties that trigger UI updates when changed

**@State**: For view-local state that persists across re-renders

**@StateObject**: For creating and owning reference types

**@EnvironmentObject**: For sharing objects across multiple views

**@AppStorage**: Property wrapper for UserDefaults persistence

## Customization Guide

### Change Timer Durations

Edit default values in `PomodoroTimer.swift`:

```swift
@AppStorage("workDuration") var workDuration: Double = 25  // Change 25
@AppStorage("shortBreakDuration") var shortBreakDuration: Double = 5
@AppStorage("longBreakDuration") var longBreakDuration: Double = 15
```

### Modify UI Colors

The app uses the system accent color. To change:

1. Open `Assets.xcassets/AccentColor.colorset`
2. Add your custom color in Xcode's color picker

### Add Custom Keyboard Shortcuts

Edit `MenuBarManager.swift`:

```swift
if event.charactersIgnoringModifiers == "t" {  // ⌘T for example
    // Your action here
    return nil
}
```

### Change Window Size

Edit dimensions in `ContentView.swift`:

```swift
.frame(width: 340, height: 500)  // Adjust these values
```

## Advanced Features to Add

Here are ideas for enhancing the app:

1. **Global Keyboard Shortcut to Start/Pause**: Use `CGEventTap` or a third-party library
2. **Statistics Dashboard**: Track daily/weekly pomodoro counts
3. **Sound Customization**: Add custom notification sounds
4. **Themes**: Light/dark mode or custom color themes
5. **Export Data**: CSV export of completed tasks and pomodoros
6. **Cloud Sync**: iCloud sync using CloudKit
7. **Menu Bar Time Display**: Show countdown in menu bar
8. **Focus Music Integration**: Play background sounds during focus time

## Troubleshooting

### App doesn't appear in menu bar

- Make sure `LSUIElement` is set to `YES` in Info.plist
- Check that you're running on macOS 14+

### Notifications don't work

- Go to System Settings → Notifications
- Find "PomodoroTimer" and enable notifications

### Build errors

- Ensure you have Xcode 15+ installed
- Clean build folder: `⌘⇧K` then rebuild

## Learning Resources

- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Swift Programming Language Guide](https://docs.swift.org/swift-book/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

## Next Steps

1. Open the project in Xcode
2. Explore each file to understand the structure
3. Run the app and test the features
4. Try making small customizations
5. Add your own features!

## License

This is a vibe coded and personal project - feel free to use and modify as needed.

Reported Issues and Pull Requests are welcome!

## Download

👉 [Download the latest macOS DMG](https://github.com/ad-h0c/PomodoroTimer/releases/latest)

## Installing the App (DMG)

1. Download the latest `PomodoroTimer.dmg` from the GitHub Releases page.
2. Double-click the DMG file to open it.
3. Drag `PomodoroTimer.app` into the `Applications` folder.
4. Eject the DMG.'

## Install with Homebrew

```bash
brew tap ad-h0c/pomodorotimer
brew install --cask pomodorotimer
```

### First Launch (Important)

Because this app is not notarized with Apple (Developer ID), macOS may show a warning.

To open the app the first time:

- Right-click `PomodoroTimer.app`
- Select **Open**
- Click **Open** again in the dialog

You only need to do this once.
