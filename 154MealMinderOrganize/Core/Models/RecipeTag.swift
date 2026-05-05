import Foundation

enum RecipeTag: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case dinner = "Dinner"
    case vegetarian = "Vegetarian"
    case quickUnder30 = "≤30 min"
    case minimalDishes = "Minimal dishes"

    var id: String { rawValue }

    /// Filter label aligned with onboarding English UI.
    var filterLabel: String { rawValue }
}

struct RecipeStepTimerHint: Codable, Equatable, Hashable {
    /// Zero-based step index aligned with ingredients/steps arrays.
    var stepIndex: Int
    /// Suggested countdown length.
    var durationMinutes: Int
}
