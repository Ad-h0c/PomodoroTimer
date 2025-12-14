# Data Storage & Persistence Guide

All your data is automatically saved and will be there when you restart your laptop.

---

## 📦 What Gets Saved

### 1. **Your Todo List** ✅

- **Storage**: `UserDefaults` with key `"todos"`
- **Format**: JSON (encoded TodoItem array)
- **Includes**:
  - Task text
  - Completion status
  - Creation date
  - Completion date and time
  - Unique ID

**Code Location**: `PomodoroTimer.swift:183-186`

```swift
private func saveTodos() {
    if let encoded = try? JSONEncoder().encode(todos) {
        UserDefaults.standard.set(encoded, forKey: "todos")
    }
}
```

**When Saved**:

- When you add a task
- When you complete/uncomplete a task
- When you edit a task
- When you delete a task

---

### 2. **Timer Settings** ✅

All customizable timer durations are saved:

| Setting              | Key                  | Default     | Storage      |
| -------------------- | -------------------- | ----------- | ------------ |
| Focus Duration       | `workDuration`       | 25 min      | UserDefaults |
| Short Break          | `shortBreakDuration` | 5 min       | UserDefaults |
| Long Break           | `longBreakDuration`  | 15 min      | UserDefaults |
| Long Break Interval  | `longBreakInterval`  | 4 pomodoros | UserDefaults |
| Auto-start Breaks    | `autoStartBreaks`    | false       | UserDefaults |
| Auto-start Pomodoros | `autoStartPomodoros` | false       | UserDefaults |

**Code Location**: `PomodoroTimer.swift:34-39`

```swift
@AppStorage("workDuration") var workDuration: Double = 25
@AppStorage("shortBreakDuration") var shortBreakDuration: Double = 5
@AppStorage("longBreakDuration") var longBreakDuration: Double = 15
@AppStorage("longBreakInterval") var longBreakInterval: Int = 4
@AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
@AppStorage("autoStartPomodoros") var autoStartPomodoros: Bool = false
```

---

### 3. **Keyboard Shortcuts** ✅

Your keyboard shortcut preferences (currently fixed, but storage exists):

| Shortcut    | Key                   | Default |
| ----------- | --------------------- | ------- |
| Start/Pause | `shortcut_startPause` | Space   |
| Reset Timer | `shortcut_reset`      | R       |
| Skip Phase  | `shortcut_skip`       | S       |

**Code Location**: `KeyboardShortcutManager.swift:9-11`

```swift
@AppStorage("shortcut_startPause") var startPauseShortcut = " "
@AppStorage("shortcut_reset") var resetShortcut = "R"
@AppStorage("shortcut_skip") var skipShortcut = "S"
```

---

## 🗄️ Where Files Are Stored

### Actual File Location

```
~/Library/Containers/com.yourcompany.PomodoroTimer/Data/Library/Preferences/com.yourcompany.PomodoroTimer.plist
```

This is a `.plist` file (Property List) - Apple's standard format for storing app preferences.

### How to View Your Data

You can inspect your saved data:

1. **Using Terminal**:

   ```bash
   defaults read com.yourcompany.PomodoroTimer
   ```

2. **Using Finder**:
   - Press `⌘⇧G` (Go to Folder)
   - Paste: `~/Library/Containers/com.yourcompany.PomodoroTimer/Data/Library/Preferences/`
   - Look for `com.yourcompany.PomodoroTimer.plist`

---

## ❌ What Does NOT Persist

### Temporary State (Resets on Restart)

| Item                             | Saved? | Why Not?                          |
| -------------------------------- | ------ | --------------------------------- |
| Current timer countdown          | ❌ No  | Intentional - timer resets        |
| Timer running state              | ❌ No  | Intentional - pauses on quit      |
| Current phase (Focus/Break)      | ❌ No  | Intentional - always starts fresh |
| Completed pomodoros count        | ❌ No  | Bug - should be saved!            |
| Text being typed (not submitted) | ❌ No  | Normal - not committed yet        |

**Note**: The completed pomodoros counter currently doesn't persist. This is something we could fix if you want!

---

## 🔄 How Data Syncing Works

### Automatic Save Triggers

**Todos** are saved immediately when you:

```swift
// Adding a task
func addTodo(_ text: String) {
    todos.append(todo)
    saveTodos()  // ← Saves instantly
}

// Toggling completion
func toggleTodo(_ todo: TodoItem) {
    todos[index].isCompleted.toggle()
    todos[index].completedAt = Date()
    saveTodos()  // ← Saves instantly
}

// Editing text
func updateTodoText(_ todo: TodoItem, newText: String) {
    todos[index].text = newText
    saveTodos()  // ← Saves instantly
}

// Deleting
func deleteTodo(at offsets: IndexSet) {
    todos.remove(atOffsets: offsets)
    saveTodos()  // ← Saves instantly
}
```

**Settings** save automatically via `@AppStorage`:

- When you move a slider in Settings
- When you toggle a switch
- No manual save needed - it's automatic!

---

## 🧪 Testing Persistence

### How to Verify Data Persists

1. **Add some tasks**:

   - "Buy groceries"
   - "Finish project"
   - "Call mom"

2. **Complete one task**:

   - Click the checkbox on "Buy groceries"

3. **Change a setting**:

   - Settings → Timer → Set Focus Duration to 30 minutes

4. **Quit the app** (`⌘Q`)

5. **Restart your Mac** (or just relaunch the app)

6. **Check**:
   - ✅ All 3 tasks should still be there
   - ✅ "Buy groceries" should still be completed
   - ✅ Focus duration should still be 30 minutes
   - ✅ Completion timestamp should be preserved

---

## 💾 Data Format Example

Here's what your saved data looks like internally:

### Todos (JSON in UserDefaults)

```json
{
  "todos": [
    {
      "id": "UUID-STRING",
      "text": "Buy groceries",
      "isCompleted": true,
      "createdAt": "2024-12-13T10:30:00Z",
      "completedAt": "2024-12-13T15:45:00Z"
    },
    {
      "id": "UUID-STRING",
      "text": "Finish project",
      "isCompleted": false,
      "createdAt": "2024-12-13T11:00:00Z",
      "completedAt": null
    }
  ]
}
```

### Settings (Key-Value Pairs)

```
workDuration = 25.0
shortBreakDuration = 5.0
longBreakDuration = 15.0
autoStartBreaks = false
autoStartPomodoros = false
```

---

## 🔒 Data Security

### Sandboxing

- Your app runs in a **sandbox** (isolated container)
- Other apps cannot access your Pomodoro data
- Your data cannot access other apps' data
- Defined in `PomodoroTimer.entitlements`

### Privacy

- All data stays **local** on your Mac
- Nothing is sent to the internet
- No cloud sync (unless you add iCloud later)
- No analytics or tracking

---

## 🚨 When Data Could Be Lost

### Data WILL be lost if:

1. ❌ You delete the app completely
2. ❌ You manually delete `~/Library/Containers/com.yourcompany.PomodoroTimer/`
3. ❌ You run `defaults delete com.yourcompany.PomodoroTimer` in Terminal
4. ❌ You change the bundle identifier in Xcode

### Data will NOT be lost if:

1. ✅ You restart your Mac
2. ✅ You quit and relaunch the app
3. ✅ Your Mac crashes
4. ✅ You rebuild the app in Xcode (during development)
5. ✅ You update macOS

---

## 🐛 Known Issue: Pomodoro Count Doesn't Persist

Currently, the completed pomodoros counter (`completedPomodoros`) is **not saved**.

### Current Behavior

```swift
@Published var completedPomodoros = 0  // ← Not saved!
```

### How to Fix (Optional)

If you want the pomodoro count to persist, we need to add:

```swift
// Change this:
@Published var completedPomodoros = 0

// To this:
@AppStorage("completedPomodoros") var completedPomodoros = 0
```

**Location**: `PomodoroTimer.swift:31`

Would you like me to fix this so your pomodoro count persists?

---

## 📊 Storage Size

Your app data is tiny:

| Data               | Typical Size |
| ------------------ | ------------ |
| 100 tasks          | ~10 KB       |
| Settings           | < 1 KB       |
| Keyboard shortcuts | < 1 KB       |
| **Total**          | **~11 KB**   |

For comparison:

- A single photo: ~3 MB (300x larger)
- A song: ~5 MB (450x larger)

You could store **thousands** of tasks before it becomes a concern.

---

## 🔄 Backup & Export

### Current State

- ✅ Auto-saved locally
- ❌ No manual backup
- ❌ No export feature
- ❌ No import feature

### Future Enhancement Ideas

1. **Export to CSV/JSON**: Save your task history
2. **Import from file**: Restore old tasks
3. **iCloud Sync**: Sync across devices
4. **Time Machine**: Automatic backups (works automatically!)

---

## ⚡ Quick Reference

### What Persists: ✅

- All your tasks and their text
- Task completion status
- Task completion dates/times
- Timer duration settings
- Auto-start preferences
- Keyboard shortcut preferences

### What Doesn't Persist: ❌

- Current timer countdown
- Timer running/paused state
- Completed pomodoros count (bug)
- Text being typed (before Enter)

### Storage Location:

```
~/Library/Containers/com.yourcompany.PomodoroTimer/
```

### View Your Data:

```bash
defaults read com.yourcompany.PomodoroTimer
```

---

## 🎯 Summary

**Yes, everything important persists!**

When you restart your Mac:

- ✅ Your tasks will be there
- ✅ Completed tasks with their dates
- ✅ Your custom settings
- ✅ Your task history

The only thing that doesn't persist is the **running timer** (which resets to the configured duration) and the **pomodoro count** (which is a bug we can fix).

Your data is safe, local, and automatically saved! 🎉
