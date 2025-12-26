# Release Notes - v1.1.0

## New Features

### Quick Add Floating Input
- Press `⌘⌥N` to open a Spotlight-like floating task input
- Draggable anywhere on screen - position it where you want
- Always on top so you can add tasks while working in other apps
- Add multiple tasks quickly - window stays open after adding
- Press `Esc` to close

### Cleaner Task List
- Completed tasks now auto-hide from the menu bar
- View completed tasks anytime in Settings → History
- Added "History" link in task header when completed tasks exist

### Task Input Improvements
- 100 character limit with visual warning
- Shows remaining characters when approaching limit
- Prevents overly long task descriptions

### Customizable Shortcuts
- All keyboard shortcuts are now customizable in Settings → Shortcuts
- Quick Add shortcut (`⌘⌥N`) added to shortcuts panel
- Click any shortcut to record a new key combination

## Bug Fixes

### Fixed App Unresponsive Issue
- Fixed critical bug where app became unresponsive on restart when accessibility permissions were already granted
- Improved permission detection with delayed initialization
- App now properly detects permission changes while running

### Improved Accessibility Permission Handling
- Added automatic detection when permissions are granted/revoked
- Global shortcuts now enable automatically when permissions are granted
- Better cleanup when permissions are revoked

## Updated Keyboard Shortcuts

| Action | Default Shortcut |
|--------|------------------|
| Start/Pause Timer | `⌘⌥↩` |
| Reset Timer | `⌘⌥R` |
| Skip Phase | `⌘⌥S` |
| Quick Add Task | `⌘⌥N` |
| Open Settings | `⌘,` |
| Quit | `⌘Q` |

## Requirements

- macOS 14.0 or later
- Accessibility permission required for global keyboard shortcuts

## Installation

### Option 1: Download DMG
Download `PomodoroTimer.dmg` from the assets below.

### Option 2: Homebrew
```bash
brew tap ad-h0c/pomodorotimer
brew install --cask pomodorotimer
```

---

**Full Changelog**: https://github.com/ad-h0c/PomodoroTimer/compare/v1.0.0...v1.1.0
