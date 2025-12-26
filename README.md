# Pomodoro Timer - macOS Menu Bar App

A native macOS Pomodoro timer application with integrated todo list that lives in your menu bar.

## Download

👉 [Download the latest macOS DMG](https://github.com/ad-h0c/PomodoroTimer/releases/latest)

## Installation

### Option 1: Download DMG

1. Download the latest `PomodoroTimer.dmg` from the GitHub Releases page
2. Double-click the DMG file to open it
3. Drag `PomodoroTimer.app` into the `Applications` folder
4. Eject the DMG

### Option 2: Install with Homebrew

```bash
brew tap ad-h0c/pomodorotimer
brew install --cask pomodorotimer
```

### ⚠️ First Launch (Important - Read This!)

**Because this app is not notarized with Apple, macOS will block it by default.**

When you first try to open the app, macOS will show a warning. Follow these steps:

1. Try to open `PomodoroTimer.app` - macOS will show a warning and block it
2. Click **Done** on the warning dialog
3. Go to **System Settings** → **Privacy & Security**
4. Scroll down to find the message about "PomodoroTimer" being blocked
5. Click **Open Anyway**
6. Confirm by clicking **Open** in the dialog

You only need to do this once. After this, the app will open normally.

### Grant Permissions

- On first launch, the app will request notification permissions
- Click "Allow" to receive timer completion notifications

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar, always accessible
- **Pomodoro Timer**: Classic 25-minute focus sessions with breaks
- **Todo List**: Full task management
  - Add tasks with the plus button or Enter key
  - Edit tasks by double-clicking or using the edit button
  - Delete tasks with the trash button (appears on hover)
  - Mark tasks as complete/incomplete
  - Completed tasks auto-hide from menu bar (visible in History)
  - 100 character limit with warning to keep tasks concise
- **Quick Add Floating Input**: Press `⌘⌥N` to open a Spotlight-like floating input
  - Always on top, draggable anywhere on screen
  - Add multiple tasks quickly without opening the menu bar
  - Press `Esc` to close
- **Customizable Durations**: Adjust focus time, short breaks, and long breaks
- **Notifications**: Get notified when sessions complete
- **Auto-start Options**: Automatically transition between work and breaks
- **Data Persistence**: Your todos and settings are saved automatically
- **Keyboard Shortcuts** (all customizable in Settings):
  - `⌘⌥↩︎` (Command + Option + Return) - Start / Pause Timer
  - `⌘⌥R` - Reset Timer
  - `⌘⌥S` - Skip Phase
  - `⌘⌥N` - Quick Add Task (floating input)
  - `⌘,` - Open Settings
  - `⌘Q` - Quit Application
- **Task History**: View completed tasks organized by date with completion timestamps

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

## Troubleshooting

### App doesn't appear in menu bar

- Check that you're running macOS 14 or later
- Try quitting and restarting the app

### Notifications don't work

- Go to System Settings → Notifications
- Find "PomodoroTimer" and enable notifications

### Global keyboard shortcuts don't work

- Go to System Settings → Privacy & Security → Accessibility
- Make sure PomodoroTimer is enabled
- If already enabled, try toggling it off and on again

### App doesn't respond

- Try quitting the app (`⌘Q`) and reopening it
- If issues persist, consider restarting your Mac

## License

This is a personal project - feel free to use and modify as needed.

Issues and Pull Requests are welcome!
