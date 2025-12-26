import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    @Environment(\.openSettings) private var openSettings
    @State private var newTodoText = ""
    private let maxTaskLength = 100

    var body: some View {
        VStack(spacing: 0) {
            timerSection
            Divider()
            todoSection
            Divider()
            bottomBar
        }
        .frame(width: 340, height: 500)
        .onAppear {
            bringPopoverToFront()
        }
    }

    private func toggleTimer() {
        if timer.isRunning {
            timer.pauseTimer()
        } else {
            timer.startTimer()
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            Text(timer.currentPhase.name)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(timer.timeString)
                .font(.system(size: 56, weight: .thin, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(action: {
                    if timer.isRunning {
                        timer.pauseTimer()
                    } else {
                        timer.startTimer()
                    }
                }) {
                    Image(systemName: timer.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help(timer.isRunning ? "Pause" : "Start")

                Button(action: {
                    timer.resetTimer()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Reset")

                Button(action: {
                    timer.skipPhase()
                }) {
                    Image(systemName: "forward.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Skip")
            }
            .foregroundColor(.accentColor)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                Text("\(timer.completedPomodoros) completed pomodoro\(timer.completedPomodoros == 1 ? "" : "s")")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                Spacer()
                Text("\(timer.todos.filter { !$0.isCompleted }.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if timer.todos.contains(where: { $0.isCompleted }) {
                    Button(action: {
                        SettingsWindowController.shared.showSettings(timer: timer, tab: .history)
                    }) {
                        Text("History")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("View completed tasks (⌘⌥H)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(timer.todos.filter { !$0.isCompleted }) { todo in
                        TodoRowView(todo: todo)
                            .environmentObject(timer)
                    }
                }
            }
            .frame(maxHeight: 200)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Button(action: {
                        addTodo()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newTodoText.count > maxTaskLength ? .secondary : .accentColor)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(newTodoText.count > maxTaskLength)

                    TextField("Add a task...", text: $newTodoText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            addTodo()
                        }
                }

                if newTodoText.count > maxTaskLength {
                    Text("Keep it short – clear tasks get done faster (\(newTodoText.count)/\(maxTaskLength))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if newTodoText.count > maxTaskLength - 20 && newTodoText.count <= maxTaskLength {
                    Text("\(maxTaskLength - newTodoText.count) characters left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                openSettings()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .font(.caption)
                .padding(4)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .contentShape(Rectangle())
            .help("Settings (⌘,)")

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 4) {
                    Text("Quit")
                }
                .font(.caption)
                .padding(4)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .contentShape(Rectangle())
            .help("Quit (⌘Q)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed.count <= maxTaskLength {
            timer.addTodo(trimmed)
            newTodoText = ""
        }
    }

    private func bringPopoverToFront() {
        NSApp.activate(ignoringOtherApps: true)
        if let statusWindow = NSApp.windows.first(where: { $0.level == .statusBar && $0.isVisible }) {
            statusWindow.makeKeyAndOrderFront(nil)
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    @EnvironmentObject var timer: PomodoroTimerModel
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                timer.toggleTodo(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editText, onCommit: {
                    saveEdit()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onAppear {
                    editText = todo.text
                }
            } else {
                Text(todo.text)
                    .font(.system(size: 13))
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .onTapGesture(count: 2) {
                        isEditing = true
                        editText = todo.text
                    }
            }

            Spacer()

            if isHovered && !isEditing {
                HStack(spacing: 8) {
                    Button(action: {
                        isEditing = true
                        editText = todo.text
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if let index = timer.todos.firstIndex(where: { $0.id == todo.id }) {
                            timer.deleteTodo(at: IndexSet(integer: index))
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            timer.updateTodoText(todo, newText: trimmed)
        }
        isEditing = false
    }
}
