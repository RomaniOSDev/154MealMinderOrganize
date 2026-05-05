import Combine
import SwiftUI

enum RecipeExplorerFilterMode: String, CaseIterable, Identifiable {
    case browse = "Browse"
    case favorites = "Favorites"

    var id: String { rawValue }
}

enum RecipeTagFilterEvaluator {
    static func passes(item: RecipeListItem, activeFilters: Set<RecipeTag>) -> Bool {
        guard !activeFilters.isEmpty else {
            return true
        }

        let itemTags = item.embeddedTags
        let minutes = item.estimatedActiveMinutes

        if activeFilters.contains(.quickUnder30) {
            guard let minutes else { return false }
            guard minutes <= 30 else { return false }
        }

        let semanticTags = activeFilters.subtracting([.quickUnder30])
        guard semanticTags.isSubset(of: itemTags) else {
            return false
        }

        return true
    }
}

@MainActor
final class RecipeExplorerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filterMode: RecipeExplorerFilterMode = .browse

    func filteredRecipeItems(
        userRecipes: [UserRecipeRecord],
        favorites: Set<String>,
        activeRecipeTags: Set<RecipeTag>
    ) -> [RecipeListItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        func matchesSearch(_ blob: String) -> Bool {
            guard !trimmed.isEmpty else { return true }
            return blob.contains(trimmed.lowercased())
        }

        let sortedUsers = userRecipes.sorted { $0.updatedAt > $1.updatedAt }
        let userItems = sortedUsers.map { RecipeListItem(user: $0) }
            .filter { matchesSearch($0.searchBlob()) }
            .filter { RecipeTagFilterEvaluator.passes(item: $0, activeFilters: activeRecipeTags) }
        let builtins = RecipeCatalog.all.map { RecipeListItem(builtin: $0) }
            .filter { matchesSearch($0.searchBlob()) }
            .filter { RecipeTagFilterEvaluator.passes(item: $0, activeFilters: activeRecipeTags) }

        let merged = userItems + builtins

        return merged.filter { item in
            let matchesFilter: Bool
            switch filterMode {
            case .browse:
                matchesFilter = true
            case .favorites:
                matchesFilter = favorites.contains(item.id)
            }

            guard matchesFilter else {
                return false
            }

            return true
        }
    }
}
