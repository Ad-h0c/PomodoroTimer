import Foundation
import Combine

class TodoStore: ObservableObject {
    @Published var todos: [TodoItem] = []

    private let saveKey = "SavedTodos"

    init() {
        loadTodos()
    }

    func addTodo(_ title: String) {
        let todo = TodoItem(title: title)
        todos.insert(todo, at: 0)
        saveTodos()
    }

    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }

    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }

    func incrementPomodoro(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].pomodoroCount += 1
            saveTodos()
        }
    }

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
}
