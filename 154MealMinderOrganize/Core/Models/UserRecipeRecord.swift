import Foundation

struct UserRecipeRecord: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var summary: String
    var previewSymbolName: String
    var ingredients: [String]
    var steps: [String]
    var hasCoverImage: Bool
    var updatedAt: Date

    var tags: [RecipeTag]
    var baseServings: Int
    var activeMinutesEstimate: Int?
    var stepTimers: [RecipeStepTimerHint]

    static let idPrefix = "user-"

    static func newDraftID() -> String {
        idPrefix + UUID().uuidString
    }

    var searchBlob: String {
        let suffix = tags.map(\.rawValue).joined(separator: " ")
        let base = title + " " + summary + " " + ingredients.joined(separator: " ") + " " + steps.joined(separator: " ") + " " + suffix
        return base.lowercased()
    }

    init(
        id: String,
        title: String,
        summary: String,
        previewSymbolName: String = "square.grid.2x2.fill",
        ingredients: [String],
        steps: [String],
        hasCoverImage: Bool,
        updatedAt: Date = Date(),
        tags: [RecipeTag] = [],
        baseServings: Int = 4,
        activeMinutesEstimate: Int? = nil,
        stepTimers: [RecipeStepTimerHint] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.previewSymbolName = previewSymbolName
        self.ingredients = ingredients
        self.steps = steps
        self.hasCoverImage = hasCoverImage
        self.updatedAt = updatedAt
        self.tags = tags
        self.baseServings = max(1, baseServings)
        self.activeMinutesEstimate = activeMinutesEstimate
        self.stepTimers = stepTimers
    }

    var recipeTagSet: Set<RecipeTag> {
        Set(tags)
    }
}

extension UserRecipeRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, summary, previewSymbolName, ingredients, steps, hasCoverImage, updatedAt
        case tags, baseServings, activeMinutesEstimate, stepTimers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decode(String.self, forKey: .summary)
        previewSymbolName = try c.decode(String.self, forKey: .previewSymbolName)
        ingredients = try c.decode([String].self, forKey: .ingredients)
        steps = try c.decode([String].self, forKey: .steps)
        hasCoverImage = try c.decode(Bool.self, forKey: .hasCoverImage)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        tags = try c.decodeIfPresent([RecipeTag].self, forKey: .tags) ?? []
        baseServings = max(1, try c.decodeIfPresent(Int.self, forKey: .baseServings) ?? 4)
        activeMinutesEstimate = try c.decodeIfPresent(Int.self, forKey: .activeMinutesEstimate)
        stepTimers = try c.decodeIfPresent([RecipeStepTimerHint].self, forKey: .stepTimers) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(summary, forKey: .summary)
        try c.encode(previewSymbolName, forKey: .previewSymbolName)
        try c.encode(ingredients, forKey: .ingredients)
        try c.encode(steps, forKey: .steps)
        try c.encode(hasCoverImage, forKey: .hasCoverImage)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(tags, forKey: .tags)
        try c.encode(baseServings, forKey: .baseServings)
        try c.encodeIfPresent(activeMinutesEstimate, forKey: .activeMinutesEstimate)
        try c.encode(stepTimers, forKey: .stepTimers)
    }
}
