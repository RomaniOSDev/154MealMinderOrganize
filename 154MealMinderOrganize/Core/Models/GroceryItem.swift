import Foundation

enum GroceryCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case bakery = "Bakery"
    case dairy = "Dairy"
    case protein = "Protein"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case misc = "Other"

    var id: String { rawValue }
}

struct GroceryItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var category: GroceryCategory
    var completed: Bool

    init(id: UUID = UUID(), name: String, category: GroceryCategory, completed: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.completed = completed
    }
}
