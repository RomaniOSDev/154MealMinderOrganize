import Combine
import SwiftUI

@MainActor
final class GroceryListViewModel: ObservableObject {
    @Published var isPresentingEditor = false
    @Published var itemBeingEdited: GroceryItem?

    @Published var draftName = ""
    @Published var draftCategory: GroceryCategory = .produce

    var isEditing: Bool { itemBeingEdited != nil }

    func beginAdd() {
        itemBeingEdited = nil
        draftName = ""
        draftCategory = .produce
        isPresentingEditor = true
    }

    func beginEdit(_ item: GroceryItem) {
        itemBeingEdited = item
        draftName = item.name
        draftCategory = item.category
        isPresentingEditor = true
    }

    func dismissEditor() {
        isPresentingEditor = false
        itemBeingEdited = nil
    }

    func shareLines(from items: [GroceryItem]) -> String {
        let lines = items.map { "- \($0.name) (\($0.category.rawValue))" }
        return lines.joined(separator: "\n")
    }
}
