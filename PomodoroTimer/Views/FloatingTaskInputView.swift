import SwiftUI
import AppKit

class FloatingTaskInputController {
    static let shared = FloatingTaskInputController()
    private var window: NSPanel?
    weak var timer: PomodoroTimerModel?

    private init() {}

    func toggle() {
        if let window = window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let timer = timer else { return }

        if window == nil {
            createWindow(timer: timer)
        }

        guard let window = window else { return }

        // Position window in center-top area of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 400
            let windowHeight: CGFloat = 80
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.maxY - windowHeight - 150
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindow(timer: PomodoroTimerModel) {
        let contentView = FloatingTaskInputView(onDismiss: { [weak self] in
            self?.hide()
        })
        .environmentObject(timer)

        let hostingController = NSHostingController(rootView: contentView)

        // Use NSPanel for floating utility window
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
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

        // Allow the panel to become key even though it's non-activating style
        panel.becomesKeyOnlyIfNeeded = false

        // Make draggable like Spotlight
        panel.isMovableByWindowBackground = true

        self.window = panel
    }
}

struct FloatingTaskInputView: View {
    @EnvironmentObject var timer: PomodoroTimerModel
    @State private var taskText = ""
    var onDismiss: () -> Void
    private let maxTaskLength = 100

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isValidInput ? .accentColor : .secondary)

            TextField("Quick add task... (Esc to close)", text: $taskText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .onSubmit {
                    addTask()
                }
                .onExitCommand {
                    onDismiss()
                }

            if !taskText.isEmpty {
                Text("\(maxTaskLength - taskText.count)")
                    .font(.caption)
                    .foregroundColor(taskText.count > maxTaskLength ? .orange : .secondary)
                    .frame(width: 30)
            }

            Button(action: addTask) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isValidInput ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!isValidInput)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .padding(8)
    }

    private var isValidInput: Bool {
        let trimmed = taskText.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= maxTaskLength
    }

    private func addTask() {
        let trimmed = taskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty && trimmed.count <= maxTaskLength else { return }

        timer.addTodo(trimmed)
        taskText = ""
        // Keep window open for adding more tasks - press Esc to close
    }
}
