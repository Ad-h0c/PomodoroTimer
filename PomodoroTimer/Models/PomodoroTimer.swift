import Foundation
import UserNotifications
import SwiftUI
import AppKit

enum PomodoroPhase {
    case work
    case shortBreak
    case longBreak

    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

    var name: String {
        switch self {
        case .work: return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

class PomodoroTimerModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var completedPomodoros: Int = UserDefaults.standard.integer(forKey: "completedPomodoros") {
        didSet {
            UserDefaults.standard.set(completedPomodoros, forKey: "completedPomodoros")
        }
    }
    @Published var todos: [TodoItem] = []
    @Published var activeTaskId: UUID? = nil
    @Published var recentlyDeletedTodo: TodoItem? = nil
    @Published var shouldShowTaskPicker = false
    @Published var recentlyUncompletedTodo: TodoItem? = nil

    @AppStorage("workDuration") var workDuration: Double = 25
    @AppStorage("shortBreakDuration") var shortBreakDuration: Double = 5
    @AppStorage("longBreakDuration") var longBreakDuration: Double = 15
    @AppStorage("longBreakInterval") var longBreakInterval: Int = 4
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
    @AppStorage("autoStartPomodoros") var autoStartPomodoros: Bool = false
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    private var timer: Timer?
    private let notificationCenter = UNUserNotificationCenter.current()
    private var timeTrackingSaveCounter: Int = 0

    init() {
        requestNotificationPermission()
        loadTodos()
    }

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startTimer() {
        playSound(named: "Glass")
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1

                // Track time for active task during work phase
                if self.currentPhase == .work, let taskId = self.activeTaskId {
                    self.addTimeToTask(taskId, seconds: 1)
                }
            } else {
                self.timerCompleted()
            }
        }
    }

    func setActiveTask(_ taskId: UUID?) {
        activeTaskId = taskId
    }

    private func addTimeToTask(_ taskId: UUID, seconds: TimeInterval) {
        if let index = todos.firstIndex(where: { $0.id == taskId }) {
            todos[index].timeSpent += seconds
            timeTrackingSaveCounter += 1
            // Save every 60 seconds to avoid excessive writes
            if timeTrackingSaveCounter >= 60 {
                saveTodos()
                timeTrackingSaveCounter = 0
            }
        }
    }

    func pauseTimer() {
        playSound(named: "Pop")
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        playSound(named: "Submarine")
        pauseTimer()
        timeRemaining = currentPhase.duration
    }

    func skipPhase() {
        playSound(named: "Ping")
        timerCompleted()
    }

    private func timerCompleted() {
        pauseTimer()

        // Save time tracking data when phase ends
        saveTodos()
        timeTrackingSaveCounter = 0

        playSound(named: "Hero")
        sendNotification(for: currentPhase)

        switch currentPhase {
        case .work:
            completedPomodoros += 1
            // Clear active task when entering break
            activeTaskId = nil

            if completedPomodoros % longBreakInterval == 0 {
                currentPhase = .longBreak
            } else {
                currentPhase = .shortBreak
            }

            if autoStartBreaks {
                timeRemaining = currentPhase.duration
                startTimer()
            } else {
                timeRemaining = currentPhase.duration
            }

        case .shortBreak, .longBreak:
            currentPhase = .work

            if autoStartPomodoros {
                timeRemaining = currentPhase.duration
                startTimer()
            } else {
                timeRemaining = currentPhase.duration
            }
        }
    }

    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendNotification(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()

        switch phase {
        case .work:
            content.title = "Pomodoro Complete!"
            content.body = "Great work! Time for a break."
        case .shortBreak, .longBreak:
            content.title = "Break is Over"
            content.body = "Ready to focus again?"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    func addTodo(_ text: String) {
        let todo = TodoItem(text: text)
        todos.append(todo)
        saveTodos()
    }

    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()

            if todos[index].isCompleted {
                todos[index].completedAt = Date()
                // Store for undo (only when completing, not uncompleting)
                recentlyUncompletedTodo = todos[index]

                // Clear undo after 10 seconds
                let completedId = todo.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                    if self?.recentlyUncompletedTodo?.id == completedId {
                        self?.recentlyUncompletedTodo = nil
                    }
                }
            } else {
                todos[index].completedAt = nil
                // Clear undo state if manually uncompleting
                if recentlyUncompletedTodo?.id == todo.id {
                    recentlyUncompletedTodo = nil
                }
            }
            saveTodos()
        }
    }

    func undoTaskCompletion() {
        guard let todo = recentlyUncompletedTodo,
              let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isCompleted = false
        todos[index].completedAt = nil
        recentlyUncompletedTodo = nil
        saveTodos()
    }

    func requestStartTimer() {
        // This triggers the task picker in the UI
        shouldShowTaskPicker = true
    }

    func updateTodoText(_ todo: TodoItem, newText: String) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].text = newText
            saveTodos()
        }
    }

    func deleteTodo(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        saveTodos()
    }

    func moveTodo(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
        saveTodos()
    }

    func clearCompletedTodos() {
        todos.removeAll { $0.isCompleted }
        saveTodos()
    }

    func deleteTodoById(_ id: UUID) {
        // Clear active task if it's being deleted
        if activeTaskId == id {
            activeTaskId = nil
        }
        todos.removeAll { $0.id == id }
        saveTodos()
    }

    func deleteTodoByIdWithUndo(_ id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            // Clear active task if it's being deleted
            if activeTaskId == id {
                activeTaskId = nil
            }
            recentlyDeletedTodo = todos[index]
            todos.remove(at: index)
            saveTodos()

            // Clear undo after 10 seconds
            let deletedId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.recentlyDeletedTodo?.id == deletedId {
                    self?.recentlyDeletedTodo = nil
                }
            }
        }
    }

    func undoDelete() {
        guard let todo = recentlyDeletedTodo else { return }
        todos.append(todo)
        recentlyDeletedTodo = nil
        saveTodos()
    }

    func formatTimeSpent(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "todos")
        }
    }

    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "todos"),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }

    private func playSound(named name: String) {
        guard soundEnabled else { return }

        // Try to play the sound safely
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            // Fallback to system beep if named sound not found
            NSSound.beep()
        }
    }
}
