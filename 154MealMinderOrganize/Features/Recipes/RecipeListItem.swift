import Foundation

enum RecipeListPayload: Hashable {
    case builtin(RecipeRecord)
    case user(UserRecipeRecord)
}

struct RecipeListItem: Identifiable, Hashable {
    let id: String
    let payload: RecipeListPayload

    init(builtin recipe: RecipeRecord) {
        id = recipe.id
        payload = .builtin(recipe)
    }

    init(user recipe: UserRecipeRecord) {
        id = recipe.id
        payload = .user(recipe)
    }

    var title: String {
        switch payload {
        case .builtin(let r): return r.title
        case .user(let u): return u.title
        }
    }

    var summary: String {
        switch payload {
        case .builtin(let r): return r.summary
        case .user(let u): return u.summary
        }
    }

    func searchBlob() -> String {
        switch payload {
        case .builtin(let r): return r.searchBlob
        case .user(let u): return u.searchBlob
        }
    }

    var ingredientsList: [String] {
        switch payload {
        case .builtin(let r): return r.ingredients
        case .user(let u): return u.ingredients
        }
    }

    var stepsList: [String] {
        switch payload {
        case .builtin(let r): return r.steps
        case .user(let u): return u.steps
        }
    }

    var previewSymbolName: String {
        switch payload {
        case .builtin(let r): return r.previewSymbol
        case .user(let u): return u.previewSymbolName
        }
    }

    var isUserOwned: Bool {
        if case .user = payload { return true }
        return false
    }

    var builtinRecipe: RecipeRecord? {
        if case let .builtin(r) = payload { return r }
        return nil
    }

    func userRecord() -> UserRecipeRecord? {
        if case let .user(u) = payload { return u }
        return nil
    }

    /// Helps SwiftUI refresh thumbnail tiles after edits.
    var tileRefreshToken: String {
        switch payload {
        case .builtin(let r): return r.id
        case .user(let u): return "\(u.id)-\(u.updatedAt.timeIntervalSince1970)"
        }
    }

    var embeddedTags: Set<RecipeTag> {
        switch payload {
        case .builtin(let r): return r.tags
        case .user(let u): return u.recipeTagSet
        }
    }

    var baseServingsCount: Int {
        switch payload {
        case .builtin(let r): return max(1, r.baseServings)
        case .user(let u): return max(1, u.baseServings)
        }
    }

    var estimatedActiveMinutes: Int? {
        switch payload {
        case .builtin(let r): return r.activeMinutesEstimate
        case .user(let u): return u.activeMinutesEstimate
        }
    }

    var embeddedStepTimers: [RecipeStepTimerHint] {
        switch payload {
        case .builtin(let r): return r.stepTimers
        case .user(let u): return u.stepTimers
        }
    }

    func timerHint(forStepIndex stepIndex: Int) -> RecipeStepTimerHint? {
        embeddedStepTimers.first { $0.stepIndex == stepIndex }
    }

    func scaledIngredientLines(multiplier: Double) -> [String] {
        ingredientsList.map {
            IngredientLineScaler.scaledLine($0, factor: multiplier)
        }
    }
}