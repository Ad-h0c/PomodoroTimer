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

    @AppStorage("workDuration") var workDuration: Double = 25
    @AppStorage("shortBreakDuration") var shortBreakDuration: Double = 5
    @AppStorage("longBreakDuration") var longBreakDuration: Double = 15
    @AppStorage("longBreakInterval") var longBreakInterval: Int = 4
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false
    @AppStorage("autoStartPomodoros") var autoStartPomodoros: Bool = false
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    private var timer: Timer?
    private let notificationCenter = UNUserNotificationCenter.current()

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
            } else {
                self.timerCompleted()
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

        playSound(named: "Hero")
        sendNotification(for: currentPhase)

        switch currentPhase {
        case .work:
            completedPomodoros += 1

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
            } else {
                todos[index].completedAt = nil
            }
            saveTodos()
        }
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
