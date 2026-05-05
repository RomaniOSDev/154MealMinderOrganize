import Foundation

struct PersistedCookingTimer: Identifiable, Equatable {
    let id: UUID
    var dishName: String
    var isPaused: Bool
    var endDate: Date?
    var pausedRemainingSeconds: Int
    var idleHoldActive: Bool
    var totalDurationSeconds: Int
    var linkedRecipeID: String?
    var linkedStepIndex: Int?

    init(
        id: UUID = UUID(),
        dishName: String,
        isPaused: Bool = false,
        endDate: Date? = nil,
        pausedRemainingSeconds: Int = 0,
        idleHoldActive: Bool = false,
        totalDurationSeconds: Int = 0,
        linkedRecipeID: String? = nil,
        linkedStepIndex: Int? = nil
    ) {
        self.id = id
        self.dishName = dishName
        self.isPaused = isPaused
        self.endDate = endDate
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.idleHoldActive = idleHoldActive
        self.totalDurationSeconds = totalDurationSeconds
        self.linkedRecipeID = linkedRecipeID
        self.linkedStepIndex = linkedStepIndex
    }

    func remainingSeconds(at date: Date) -> Int {
        if isPaused {
            return max(0, pausedRemainingSeconds)
        }
        if let endDate {
            return max(0, Int(endDate.timeIntervalSince(date).rounded(.down)))
        }
        return 0
    }

    mutating func toggleUserPause(at date: Date) {
        idleHoldActive = false
        if isPaused {
            isPaused = false
            endDate = date.addingTimeInterval(TimeInterval(max(1, pausedRemainingSeconds)))
            pausedRemainingSeconds = 0
        } else {
            let remaining = remainingSeconds(at: date)
            isPaused = true
            endDate = nil
            pausedRemainingSeconds = remaining
        }
    }

    mutating func freezeIfRunningForIdle(at date: Date) {
        guard !isPaused, endDate != nil else { return }
        let remaining = remainingSeconds(at: date)
        isPaused = true
        endDate = nil
        pausedRemainingSeconds = remaining
        idleHoldActive = true
    }

    mutating func resumeIfIdleHeld(at date: Date) {
        guard idleHoldActive else { return }
        idleHoldActive = false
        isPaused = false
        endDate = date.addingTimeInterval(TimeInterval(max(1, pausedRemainingSeconds)))
        pausedRemainingSeconds = 0
    }

    mutating func reset(durationSeconds: Int, from date: Date) {
        totalDurationSeconds = max(10, durationSeconds)
        isPaused = false
        pausedRemainingSeconds = 0
        idleHoldActive = false
        endDate = date.addingTimeInterval(TimeInterval(totalDurationSeconds))
    }
}

extension PersistedCookingTimer: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case dishName
        case isPaused
        case endDate
        case pausedRemainingSeconds
        case idleHoldActive
        case totalDurationSeconds
        case linkedRecipeID
        case linkedStepIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dishName = try container.decode(String.self, forKey: .dishName)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        pausedRemainingSeconds = try container.decodeIfPresent(Int.self, forKey: .pausedRemainingSeconds) ?? 0
        idleHoldActive = try container.decodeIfPresent(Bool.self, forKey: .idleHoldActive) ?? false
        totalDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .totalDurationSeconds) ?? 300
        linkedRecipeID = try container.decodeIfPresent(String.self, forKey: .linkedRecipeID)
        linkedStepIndex = try container.decodeIfPresent(Int.self, forKey: .linkedStepIndex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dishName, forKey: .dishName)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(pausedRemainingSeconds, forKey: .pausedRemainingSeconds)
        try container.encode(idleHoldActive, forKey: .idleHoldActive)
        try container.encode(totalDurationSeconds, forKey: .totalDurationSeconds)
        try container.encodeIfPresent(linkedRecipeID, forKey: .linkedRecipeID)
        try container.encodeIfPresent(linkedStepIndex, forKey: .linkedStepIndex)
    }
}
