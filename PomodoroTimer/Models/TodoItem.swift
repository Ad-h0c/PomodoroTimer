import Foundation

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var timeSpent: TimeInterval

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, createdAt: Date = Date(), completedAt: Date? = nil, timeSpent: TimeInterval = 0) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.timeSpent = timeSpent
    }

    // Custom decoder for backward compatibility with existing todos without timeSpent
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        timeSpent = try container.decodeIfPresent(TimeInterval.self, forKey: .timeSpent) ?? 0
    }
}
