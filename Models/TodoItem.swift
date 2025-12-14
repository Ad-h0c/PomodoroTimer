import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var pomodoroCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, createdAt, pomodoroCount
    }
}
