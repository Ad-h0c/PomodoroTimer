import SwiftUI
import AppKit

// Custom panel that can become key window even when borderless
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class FloatingTaskPickerController {
    static let shared = FloatingTaskPickerController()
    private var window: NSPanel?
    weak var timer: PomodoroTimerModel?
    var onTaskSelected: ((UUID?) -> Void)?

    private init() {}

    func show(onSelect: @escaping (UUID?) -> Void) {
        // Must run on main thread for UI operations
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.show(onSelect: onSelect)
            }
            return
        }

        guard let timer = timer else {
            onSelect(nil)
            return
        }

        self.onTaskSelected = onSelect

        // Always recreate the window to get fresh state from timer
        // This avoids stale EnvironmentObject issues
        window?.close()
        window = nil
        createWindow(timer: timer)

        guard let window = window else { return }

        // Position window in center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 480
            let windowHeight: CGFloat = 420
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.minY + (screenFrame.height * 0.6) - (windowHeight / 2)
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        // Use async to ensure window presentation happens in next run loop iteration
        // This helps avoid timing issues with AppKit window management
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func hide() {
        window?.orderOut(nil)
    }

    func cancel() {
        hide()
    }

    func selectTask(_ taskId: UUID?) {
        onTaskSelected?(taskId)
        hide()
    }

    private func createWindow(timer: PomodoroTimerModel) {
        let contentView = FloatingTaskPickerView(
            onSelect: { [weak self] taskId in
                self?.selectTask(taskId)
            },
            onSkip: { [weak self] in
                self?.selectTask(nil)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )
        .environmentObject(timer)

        let hostingController = NSHostingController(rootView: contentView)

        // Use borderless KeyablePanel for clean appearance with proper focus
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hostingController
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.level = .floating
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.becomesKeyOnlyIfNeeded = false
        panel.isMovableByWindowBackground = true

        self.window = panel
    }
}

struct FloatingTaskPickerView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    @State private var searchText = ""
    @State private var hoveredTaskId: UUID? = nil
    @FocusState private var isSearchFocused: Bool

    let onSelect: (UUID?) -> Void
    let onSkip: () -> Void
    let onCancel: () -> Void

    private let maxTaskLength = 100

    var filteredTasks: [TodoItem] {
        let active = timer.todos.filter { !$0.isCompleted }
        if searchText.isEmpty {
            return active
        }
        return active.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            searchSection

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)

            if filteredTasks.isEmpty {
                emptyState
            } else {
                taskListSection
            }

            footerSection
        }
        .frame(width: 480, height: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // Focus the search field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)

                Text("Select Task")
                    .font(.system(size: 14, weight: .semibold))
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search or create task...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isSearchFocused)
                .onSubmit { handleSubmit() }
                .onExitCommand { onCancel() }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredTasks) { task in
                    taskRow(task: task)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }

    private func taskRow(task: TodoItem) -> some View {
        Button(action: { onSelect(task.id) }) {
            HStack(spacing: 12) {
                Circle()
                    .stroke(hoveredTaskId == task.id ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.text)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if task.timeSpent > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(timer.formatTimeSpent(task.timeSpent))
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.blue.opacity(0.7))
                    }
                }

                Spacer()

                if hoveredTaskId == task.id {
                    Text("Start →")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hoveredTaskId == task.id ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hoveredTaskId = $0 ? task.id : nil }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if searchText.isEmpty {
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("No active tasks")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                Text("Create \"\(searchText.prefix(30))\"")
                    .font(.system(size: 14, weight: .medium))
                Text("Press Return to create and start")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !searchText.isEmpty { createAndSelect() }
        }
    }

    private var footerSection: some View {
        HStack {
            HStack(spacing: 12) {
                Text("↵ Select").font(.caption).foregroundColor(.secondary)
                Text("esc Close").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onSkip) {
                Text("Start without task →")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    private func handleSubmit() {
        if let first = filteredTasks.first {
            onSelect(first.id)
        } else if !searchText.isEmpty {
            createAndSelect()
        }
    }

    private func createAndSelect() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty && trimmed.count <= maxTaskLength else { return }
        timer.addTodo(trimmed)
        if let newTask = timer.todos.last {
            onSelect(newTask.id)
        }
    }
}
