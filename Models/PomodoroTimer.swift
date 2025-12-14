import Foundation
import Combine
import UserNotifications

enum TimerState {
    case idle
    case running
    case paused
}

enum PomodoroPhase {
    case work
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .work: return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var state: TimerState = .idle
    @Published var phase: PomodoroPhase = .work
    @Published var completedPomodoros: Int = 0

    private var timer: Timer?
    private var workDuration: TimeInterval = 25 * 60
    private var shortBreakDuration: TimeInterval = 5 * 60
    private var longBreakDuration: TimeInterval = 15 * 60
    private let pomodorosUntilLongBreak = 4

    var progress: Double {
        let totalTime = currentPhaseDuration
        return totalTime > 0 ? 1.0 - (timeRemaining / totalTime) : 0
    }

    var currentPhaseDuration: TimeInterval {
        switch phase {
        case .work: return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        state = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        state = .idle
        timer?.invalidate()
        timer = nil
        timeRemaining = currentPhaseDuration
    }

    func skip() {
        completePhase()
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completePhase()
        }
    }

    private func completePhase() {
        timer?.invalidate()
        timer = nil
        state = .idle

        // Send notification
        sendNotification(for: phase)

        // Move to next phase
        switch phase {
        case .work:
            completedPomodoros += 1
            if completedPomodoros % pomodorosUntilLongBreak == 0 {
                phase = .longBreak
            } else {
                phase = .shortBreak
            }
        case .shortBreak, .longBreak:
            phase = .work
        }

        timeRemaining = currentPhaseDuration
    }

    private func sendNotification(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()

        switch phase {
        case .work:
            content.title = "Focus Time Complete!"
            content.body = "Great job! Time for a break."
        case .shortBreak:
            content.title = "Break Complete!"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long Break Complete!"
            content.body = "You've earned it! Ready for another session?"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func updateSettings(work: Int, shortBreak: Int, longBreak: Int) {
        workDuration = TimeInterval(work * 60)
        shortBreakDuration = TimeInterval(shortBreak * 60)
        longBreakDuration = TimeInterval(longBreak * 60)

        if state == .idle {
            timeRemaining = currentPhaseDuration
        }
    }
}
