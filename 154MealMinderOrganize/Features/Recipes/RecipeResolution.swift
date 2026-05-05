import Foundation

enum RecipeResolution {
    /// Returns merged list item using the freshest user record when applicable.
    static func listItem(recipeID: String, store: MealPlannerStore) -> RecipeListItem? {
        if let user = store.userRecipes.first(where: { $0.id == recipeID }) {
            return RecipeListItem(user: user)
        }
        if let built = RecipeCatalog.all.first(where: { $0.id == recipeID }) {
            return RecipeListItem(builtin: built)
        }
        return nil
    }

    static func title(recipeID: String, store: MealPlannerStore) -> String {
        listItem(recipeID: recipeID, store: store)?.title ?? "Recipe"
    }
}
