import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    @State private var selectedTab: SettingsTab

    init(initialTab: SettingsTab? = nil) {
        _selectedTab = State(initialValue: initialTab ?? .timer)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header spacing
            Spacer()
                .frame(height: 12)

            TabView(selection: $selectedTab) {
                TimerSettingsView()
                    .environmentObject(timer)
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(SettingsTab.timer)

                HistoryView()
                    .environmentObject(timer)
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(SettingsTab.history)

                KeyboardShortcutsView()
                    .tabItem {
                        Label("Shortcuts", systemImage: "command")
                    }
                    .tag(SettingsTab.shortcuts)

                GeneralSettingsView()
                    .environmentObject(timer)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(SettingsTab.general)

                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(SettingsTab.about)
            }
            .padding(.horizontal, 1)
            .onReceive(NotificationCenter.default.publisher(for: .showSettingsTab)) { note in
                if let raw = note.userInfo?["tab"] as? String,
                   let tab = SettingsTab(rawValue: raw) {
                    selectedTab = tab
                }
            }
        }
        .frame(width: 600, height: 600)
        .background(TabViewFocusRemover())
    }

    private func removeFocusRingFromAllTabViews() {
        for window in NSApp.windows {
            removeFocusRing(from: window.contentView)
        }
    }

    private func removeFocusRing(from view: NSView?) {
        guard let view = view else { return }

        if let tabView = view as? NSTabView {
            tabView.focusRingType = .none
        }

        for subview in view.subviews {
            removeFocusRing(from: subview)
        }
    }
}

struct TabViewFocusRemover: NSViewRepresentable {
    func makeNSView(context: Context) -> FocusRemoverView {
        return FocusRemoverView()
    }

    func updateNSView(_ nsView: FocusRemoverView, context: Context) {
        nsView.removeFocusRing()
    }

    class FocusRemoverView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            removeFocusRing()
        }

        func removeFocusRing() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Search up the view hierarchy
                var currentView: NSView? = self
                while let view = currentView {
                    if let tabView = view as? NSTabView {
                        tabView.focusRingType = .none
                        return
                    }
                    currentView = view.superview
                }

                // Also search down from window
                if let window = self.window {
                    self.searchAndDisableFocusRing(in: window.contentView)
                }
            }
        }

        private func searchAndDisableFocusRing(in view: NSView?) {
            guard let view = view else { return }

            if let tabView = view as? NSTabView {
                tabView.focusRingType = .none
            }

            for subview in view.subviews {
                searchAndDisableFocusRing(in: subview)
            }
        }
    }
}

struct TimerSettingsView: View {
    @EnvironmentObject var timer: PomodoroTimerModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Duration Cards
                VStack(spacing: 12) {
                    durationCard(
                        icon: "brain.head.profile",
                        title: "Focus Time",
                        value: $timer.workDuration,
                        range: 1...60,
                        color: .blue
                    )

                    durationCard(
                        icon: "cup.and.saucer.fill",
                        title: "Short Break",
                        value: $timer.shortBreakDuration,
                        range: 1...30,
                        color: .green
                    )

                    durationCard(
                        icon: "figure.walk",
                        title: "Long Break",
                        value: $timer.longBreakDuration,
                        range: 5...60,
                        color: .purple
                    )
                }

                // Interval Card
                HStack(spacing: 12) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Long Break Interval")
                            .font(.system(size: 14, weight: .medium))
                        Text("After every \(timer.longBreakInterval) focus sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Stepper(value: $timer.longBreakInterval, in: 2...10) {
                        Text("\(timer.longBreakInterval)")
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                            .frame(minWidth: 20)
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)

                Divider()
                    .padding(.vertical, 4)

                // Auto-start Options
                VStack(spacing: 12) {
                    autoStartCard(
                        icon: "play.circle.fill",
                        title: "Auto-start Breaks",
                        subtitle: "Automatically begin breaks after focus sessions",
                        isOn: $timer.autoStartBreaks,
                        color: .green
                    )

                    autoStartCard(
                        icon: "bolt.circle.fill",
                        title: "Auto-start Focus",
                        subtitle: "Automatically begin focus after breaks end",
                        isOn: $timer.autoStartPomodoros,
                        color: .blue
                    )
                }

                // Reset Button
                Button(action: resetToDefaults) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.secondary)
            }
            .padding(20)
        }
    }

    private func durationCard(icon: String, title: String, value: Binding<Double>, range: ClosedRange<Double>, color: Color) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Spacer()

                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
                    .frame(minWidth: 50, alignment: .trailing)

                Text("min")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Slider(value: value, in: range, step: 1)
                .tint(color)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func autoStartCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func resetToDefaults() {
        timer.workDuration = 25
        timer.shortBreakDuration = 5
        timer.longBreakDuration = 15
        timer.longBreakInterval = 4
        timer.autoStartBreaks = false
        timer.autoStartPomodoros = false
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    @AppStorage("showDockIcon") private var showDockIcon = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Statistics Cards
                VStack(spacing: 12) {
                    statCard(
                        icon: "checkmark.circle.fill",
                        title: "Completed Pomodoros",
                        value: "\(timer.completedPomodoros)",
                        color: .blue
                    )

                    statCard(
                        icon: "list.bullet.circle.fill",
                        title: "Active Tasks",
                        value: "\(timer.todos.filter { !$0.isCompleted }.count)",
                        color: .orange
                    )

                    statCard(
                        icon: "checkmark.seal.fill",
                        title: "Completed Tasks",
                        value: "\(timer.todos.filter { $0.isCompleted }.count)",
                        color: .green
                    )
                }

                Divider()
                    .padding(.vertical, 4)

                // Audio Card
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound Effects")
                            .font(.system(size: 14, weight: .medium))
                        Text("Play sounds for timer events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $timer.soundEnabled)
                        .labelsHidden()
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)

                Divider()
                    .padding(.vertical, 4)

                // Dock Icon Toggle
                HStack(spacing: 12) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Dock Icon")
                            .font(.system(size: 14, weight: .medium))
                        Text("Hide or show the app icon in the Dock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $showDockIcon)
                        .labelsHidden()
                        .onChange(of: showDockIcon) { newValue in
                            applyDockVisibility(newValue)
                        }
                        .onAppear {
                            applyDockVisibility(showDockIcon)
                        }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)

                Divider()
                    .padding(.vertical, 4)

                // Data Management Cards
                VStack(spacing: 12) {
                    Button(action: clearCompletedTasks) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clear Completed Tasks")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Remove all completed tasks from your list")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: { timer.completedPomodoros = 0 }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Pomodoro Count")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Reset your completion counter to zero")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 14, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func clearCompletedTasks() {
        timer.clearCompletedTodos()
    }

    private func applyDockVisibility(_ show: Bool) {
        NSApp.setActivationPolicy(show ? .regular : .accessory)
        if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

struct KeyboardShortcutsView: View {
    @ObservedObject var manager = KeyboardShortcutManager.shared
    @State private var editingStartPause = false
    @State private var editingReset = false
    @State private var editingSkip = false
    @State private var editingQuickAdd = false

    private enum ShortcutTarget {
        case startPause
        case reset
        case skip
        case quickAdd
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer Controls
                VStack(spacing: 12) {
                    shortcutCard(
                        icon: "play.circle.fill",
                        title: "Start / Pause",
                        subtitle: "Toggle the timer on and off",
                        shortcut: $manager.startPauseShortcut,
                        isEditing: $editingStartPause,
                        placeholder: "Space",
                        color: .blue,
                        onBeginEditing: { beginEditing(.startPause) }
                    )

                    shortcutCard(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: "Reset Timer",
                        subtitle: "Reset current timer to start",
                        shortcut: $manager.resetShortcut,
                        isEditing: $editingReset,
                        placeholder: "⌘R",
                        color: .orange,
                        onBeginEditing: { beginEditing(.reset) }
                    )

                    shortcutCard(
                        icon: "forward.circle.fill",
                        title: "Skip Phase",
                        subtitle: "Move to next timer phase",
                        shortcut: $manager.skipShortcut,
                        isEditing: $editingSkip,
                        placeholder: "⌘F",
                        color: .purple,
                        onBeginEditing: { beginEditing(.skip) }
                    )

                    shortcutCard(
                        icon: "plus.circle.fill",
                        title: "Quick Add Task",
                        subtitle: "Open floating task input",
                        shortcut: $manager.quickAddShortcut,
                        isEditing: $editingQuickAdd,
                        placeholder: "⌘⌥N",
                        color: .green,
                        onBeginEditing: { beginEditing(.quickAdd) }
                    )
                }

                Divider()
                    .padding(.vertical, 4)

                // System Shortcuts
                VStack(spacing: 12) {
                    systemShortcutCard(
                        icon: "gearshape.circle.fill",
                        title: "Open Settings",
                        shortcut: "⌘,",
                        color: .gray
                    )

                    systemShortcutCard(
                        icon: "power.circle.fill",
                        title: "Quit Application",
                        shortcut: "⌘Q",
                        color: .red
                    )
                }

                // Info Card
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)

                    Text("Click any shortcut above to customize it, then press your desired key combination.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)

                // Reset Button
                Button(action: resetToDefaults) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Shortcuts")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.secondary)
            }
            .padding(20)
        }
        .onChange(of: editingStartPause) { _, _ in
            updateEditingState()
        }
        .onChange(of: editingReset) { _, _ in
            updateEditingState()
        }
        .onChange(of: editingSkip) { _, _ in
            updateEditingState()
        }
        .onChange(of: editingQuickAdd) { _, _ in
            updateEditingState()
        }
    }

    private func shortcutCard(
        icon: String,
        title: String,
        subtitle: String,
        shortcut: Binding<KeyboardShortcutManager.Shortcut>,
        isEditing: Binding<Bool>,
        placeholder: String,
        color: Color,
        onBeginEditing: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                onBeginEditing()
                isEditing.wrappedValue = true
            }) {
                Text(isEditing.wrappedValue ? "Press keys..." : displayShortcut(shortcut.wrappedValue, placeholder: placeholder))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(isEditing.wrappedValue ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isEditing.wrappedValue ? color : Color(nsColor: NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isEditing.wrappedValue ? color : Color(nsColor: NSColor.separatorColor), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .background(
                KeyEventHandlerView(
                    isCapturing: isEditing,
                    onShortcutCaptured: { captured in
                        shortcut.wrappedValue = captured
                        isEditing.wrappedValue = false
                    }
                )
            )
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func systemShortcutCard(icon: String, title: String, shortcut: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 14, weight: .medium))

            Spacer()

            Text(shortcut)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 1)
                )
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func resetToDefaults() {
        manager.startPauseShortcut = .defaultStartPause
        manager.resetShortcut = .defaultReset
        manager.skipShortcut = .defaultSkip
        manager.quickAddShortcut = .defaultQuickAdd

        editingStartPause = false
        editingReset = false
        editingSkip = false
        editingQuickAdd = false
        updateEditingState()
    }

    private func beginEditing(_ target: ShortcutTarget) {
        editingStartPause = target == .startPause
        editingReset = target == .reset
        editingSkip = target == .skip
        editingQuickAdd = target == .quickAdd
        updateEditingState()
    }

    private func displayShortcut(_ shortcut: KeyboardShortcutManager.Shortcut, placeholder: String) -> String {
        let display = shortcut.displayString.replacingOccurrences(of: " ", with: " + ")
        return display.trimmingCharacters(in: .whitespaces).isEmpty ? placeholder : display
    }

    private func updateEditingState() {
        manager.isEditingShortcut = editingStartPause || editingReset || editingSkip || editingQuickAdd
    }
}

struct KeyEventHandlerView: NSViewRepresentable {
    @Binding var isCapturing: Bool
    let onShortcutCaptured: (KeyboardShortcutManager.Shortcut) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onShortcutCaptured = { shortcut in
            onShortcutCaptured(shortcut)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.isCapturing = isCapturing
    }

    class KeyCaptureView: NSView {
        var isCapturing = false {
            didSet {
                if isCapturing && oldValue != isCapturing {
                    DispatchQueue.main.async { [weak self] in
                        self?.attemptBecomeFirstResponder()
                    }
                }
            }
        }
        var onShortcutCaptured: ((KeyboardShortcutManager.Shortcut) -> Void)?

        override var acceptsFirstResponder: Bool { isCapturing }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if isCapturing {
                DispatchQueue.main.async { [weak self] in
                    self?.attemptBecomeFirstResponder()
                }
            }
        }

        private func attemptBecomeFirstResponder() {
            guard isCapturing, let window = window else { return }

            // Only try to become first responder if window is key
            if window.isKeyWindow {
                window.makeFirstResponder(self)
            }
        }

        override func keyDown(with event: NSEvent) {
            guard isCapturing else {
                super.keyDown(with: event)
                return
            }

            if let shortcut = KeyboardShortcutManager.Shortcut(event: event) {
                onShortcutCaptured?(shortcut)
            }
        }

        override func becomeFirstResponder() -> Bool {
            return isCapturing
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var timer: PomodoroTimerModel

    var completedTodosByDate: [(String, [TodoItem])] {
        let completed = timer.todos.filter { $0.isCompleted && $0.completedAt != nil }
        let grouped = Dictionary(grouping: completed) { todo -> String in
            guard let date = todo.completedAt else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: date)
        }

        return grouped.sorted { first, second in
            guard let firstDate = first.value.first?.completedAt,
                  let secondDate = second.value.first?.completedAt else {
                return false
            }
            return firstDate > secondDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if completedTodosByDate.isEmpty {
                    emptyStateView
                } else {
                    // Summary Card
                    summaryCard

                    Divider()
                        .padding(.vertical, 4)

                    // History Cards by Date
                    ForEach(completedTodosByDate, id: \.0) { date, tasks in
                        dateGroupCard(date: date, tasks: tasks)
                    }
                }
            }
            .padding(20)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("No Completed Tasks Yet")
                    .font(.system(size: 18, weight: .semibold))
                Text("Complete tasks in the main view to see your achievement history here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(timer.todos.filter { $0.isCompleted }.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(completedTodosByDate.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(completedTodosByDate.first?.1.count ?? 0)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func dateGroupCard(date: String, tasks: [TodoItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text(date)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    taskRow(task: task)

                    if index < tasks.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }

    private func taskRow(task: TodoItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)

            Text(task.text)
                .font(.system(size: 14))
                .lineLimit(2)

            Spacer()

            if let completedAt = task.completedAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(formatTime(completedAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct AboutView: View {
    @ObservedObject var shortcutManager = KeyboardShortcutManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Permission Alert (if needed)
                if shortcutManager.needsAccessibilityPermission {
                    permissionAlert
                }
                // App Icon and Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Text("🍅")
                            .font(.system(size: 64))
                    }

                    VStack(spacing: 8) {
                        Text("Pomodoro Timer")
                            .font(.system(size: 28, weight: .bold))

                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Stay focused, get things done")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                Divider()

                // How to Use
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        Text("How to Use")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        helpItem(
                            icon: "1.circle.fill",
                            color: .blue,
                            title: "Set Your Timer",
                            description: "Configure your focus and break durations in the Timer tab"
                        )

                        helpItem(
                            icon: "2.circle.fill",
                            color: .green,
                            title: "Add Tasks",
                            description: "Create tasks in the main menu to track what you're working on"
                        )

                        helpItem(
                            icon: "3.circle.fill",
                            color: .orange,
                            title: "Use Shortcuts",
                            description: "Control the timer from anywhere with global keyboard shortcuts"
                        )

                        helpItem(
                            icon: "4.circle.fill",
                            color: .purple,
                            title: "Track Progress",
                            description: "View your completed tasks and pomodoros in the History tab"
                        )
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)

                // Keyboard Shortcuts Help
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                        Text("Default Shortcuts")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    VStack(spacing: 8) {
                        shortcutHelpRow(key: "⌘⌥↩", action: "Start / Pause Timer")
                        Divider()
                        shortcutHelpRow(key: "⌘⌥R", action: "Reset Timer")
                        Divider()
                        shortcutHelpRow(key: "⌘⌥S", action: "Skip Phase")
                        Divider()
                        shortcutHelpRow(key: "⌘,", action: "Open Settings")
                        Divider()
                        shortcutHelpRow(key: "⌘Q", action: "Quit App")
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)


                // Footer
                VStack(spacing: 8) {
                    Text("Made with ❤️ using SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("© 2025 Pomodoro Timer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .padding(20)
        }
    }

    private var permissionAlert: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility Permission Required")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Global keyboard shortcuts need accessibility access to work system-wide")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Text("Without this permission, shortcuts will only work when the menu bar is open.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 40)

            HStack(spacing: 12) {
                Button("Check Again") {
                    if AXIsProcessTrusted() {
                        shortcutManager.setupGlobalMonitor()
                    }
                }
                .controlSize(.large)

                Spacer()

                Button("Open System Settings") {
                    shortcutManager.openAccessibilitySettings()
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func helpItem(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func shortcutHelpRow(key: String, action: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 13))

            Spacer()

            Text(key)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}
