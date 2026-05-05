import Foundation

struct RecipeComment: Identifiable, Hashable {
    let id: UUID
    let author: String
    let message: String

    init(id: UUID = UUID(), author: String, message: String) {
        self.id = id
        self.author = author
        self.message = message
    }
}

struct RecipeRecord: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let previewSymbol: String
    let ingredients: [String]
    let steps: [String]
    let averageRating: Double
    let ratingCount: Int
    let comments: [RecipeComment]
    let tags: Set<RecipeTag>
    let baseServings: Int
    let activeMinutesEstimate: Int?
    let stepTimers: [RecipeStepTimerHint]

    init(
        id: String,
        title: String,
        summary: String,
        previewSymbol: String,
        ingredients: [String],
        steps: [String],
        averageRating: Double,
        ratingCount: Int,
        comments: [RecipeComment],
        tags: Set<RecipeTag> = [],
        baseServings: Int = 4,
        activeMinutesEstimate: Int? = nil,
        stepTimers: [RecipeStepTimerHint] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.previewSymbol = previewSymbol
        self.ingredients = ingredients
        self.steps = steps
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.comments = comments
        self.tags = tags
        self.baseServings = baseServings
        self.activeMinutesEstimate = activeMinutesEstimate
        self.stepTimers = stepTimers
    }

    var searchBlob: String {
        let suffix = tags.map(\.rawValue).joined(separator: " ")
        let base = title + " " + summary + " " + ingredients.joined(separator: " ") + " " + suffix
        return base.lowercased()
    }
}

enum RecipeCatalog {
    static let all: [RecipeRecord] = [
        RecipeRecord(
            id: "lemon-herb-salmon",
            title: "Lemon Herb Salmon",
            summary: "Bright citrus, tender fillets, and a crisp herb crust.",
            previewSymbol: "fish.fill",
            ingredients: [
                "Salmon fillets",
                "Lemon zest and juice",
                "Olive oil",
                "Garlic",
                "Fresh dill",
                "Sea salt",
                "Black pepper"
            ],
            steps: [
                "Pat salmon dry and season.",
                "Whisk oil, lemon, garlic, and chopped dill.",
                "Brush fillets and bake at 200°C until flaky.",
                "Finish with extra lemon and cracked pepper."
            ],
            averageRating: 4.8,
            ratingCount: 214,
            comments: [
                RecipeComment(author: "Mara", message: "My family asks for this every Friday."),
                RecipeComment(author: "Leo", message: "Quick enough for a weeknight dinner.")
            ],
            tags: [.dinner],
            baseServings: 4,
            activeMinutesEstimate: 38,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 14)]
        ),
        RecipeRecord(
            id: "one-pot-tomato-basil-pasta",
            title: "One-Pot Tomato Basil Pasta",
            summary: "Silky sauce and al dente noodles with minimal cleanup.",
            previewSymbol: "takeoutbag.and.cup.and.straw.fill",
            ingredients: [
                "Spaghetti",
                "Cherry tomatoes",
                "Basil leaves",
                "Vegetable stock",
                "Parmesan",
                "Shallot",
                "Chili flakes"
            ],
            steps: [
                "Sauté shallot and tomatoes until jammy.",
                "Add pasta and stock, simmer until tender.",
                "Stir in basil and cheese off heat.",
                "Season and serve immediately."
            ],
            averageRating: 4.6,
            ratingCount: 432,
            comments: [
                RecipeComment(author: "Ines", message: "Great for late study nights."),
                RecipeComment(author: "Owen", message: "I added grilled chicken on top.")
            ],
            tags: [.dinner, .vegetarian, .minimalDishes, .quickUnder30],
            baseServings: 4,
            activeMinutesEstimate: 28,
            stepTimers: [RecipeStepTimerHint(stepIndex: 1, durationMinutes: 12)]
        ),
        RecipeRecord(
            id: "crispy-oven-tacos",
            title: "Crispy Oven Tacos",
            summary: "Cheesy shells that crisp in the oven for easy assembly.",
            previewSymbol: "flame.fill",
            ingredients: [
                "Corn tortillas",
                "Black beans",
                "Ground turkey",
                "Smoked paprika",
                "Cheddar",
                "Onion",
                "Lime"
            ],
            steps: [
                "Cook turkey with onion and spices.",
                "Fill tortillas, add beans and cheese.",
                "Bake until shells are golden.",
                "Top with lime and herbs."
            ],
            averageRating: 4.7,
            ratingCount: 305,
            comments: [
                RecipeComment(author: "Priya", message: "Kids devoured the crispy edges."),
                RecipeComment(author: "Sam", message: "Swap beans for chickpeas—still great.")
            ],
            tags: [.dinner, .minimalDishes, .quickUnder30],
            baseServings: 6,
            activeMinutesEstimate: 32,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 14)]
        ),
        RecipeRecord(
            id: "mushroom-risotto",
            title: "Wild Mushroom Risotto",
            summary: "Earthy mushrooms balanced with bright stock and butter.",
            previewSymbol: "leaf.fill",
            ingredients: [
                "Arborio rice",
                "Mixed mushrooms",
                "White wine",
                "Vegetable stock",
                "Butter",
                "Shallot",
                "Thyme"
            ],
            steps: [
                "Sauté mushrooms until golden, set aside.",
                "Toast rice, deglaze with wine.",
                "Ladle stock slowly, stirring often.",
                "Fold mushrooms, butter, and herbs to finish."
            ],
            averageRating: 4.9,
            ratingCount: 188,
            comments: [
                RecipeComment(author: "Clara", message: "Restaurant-level comfort."),
                RecipeComment(author: "Noah", message: "Used porcini for deeper flavor.")
            ],
            tags: [.dinner, .vegetarian],
            baseServings: 4,
            activeMinutesEstimate: 55,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 35)]
        ),
        RecipeRecord(
            id: "sheet-pan-fajitas",
            title: "Sheet-Pan Fajitas",
            summary: "Charred peppers, sizzling spices, and warm tortillas.",
            previewSymbol: "square.grid.3x3.fill",
            ingredients: [
                "Bell peppers",
                "Red onion",
                "Skirt steak or portobello",
                "Cumin",
                "Smoked paprika",
                "Lime",
                "Flour tortillas"
            ],
            steps: [
                "Toss vegetables with oil and spices.",
                "Roast with protein until edges char.",
                "Squeeze lime and toss.",
                "Serve with warm tortillas."
            ],
            averageRating: 4.5,
            ratingCount: 267,
            comments: [
                RecipeComment(author: "Hannah", message: "Meal prep friendly—held well."),
                RecipeComment(author: "Diego", message: "Extra lime is essential.")
            ],
            tags: [.dinner, .minimalDishes, .quickUnder30],
            baseServings: 6,
            activeMinutesEstimate: 34,
            stepTimers: [RecipeStepTimerHint(stepIndex: 1, durationMinutes: 18)]
        ),
        RecipeRecord(
            id: "greek-yogurt-parfait-bar",
            title: "Greek Yogurt Parfait Bar",
            summary: "Layered yogurt, fruit, and crunchy toppings for breakfast.",
            previewSymbol: "cup.and.saucer.fill",
            ingredients: [
                "Greek yogurt",
                "Honey",
                "Berries",
                "Granola",
                "Chia seeds",
                "Mint",
                "Cinnamon"
            ],
            steps: [
                "Sweeten yogurt with honey and cinnamon.",
                "Layer fruit and crunchy toppings.",
                "Top with mint leaves.",
                "Serve chilled in glasses."
            ],
            averageRating: 4.4,
            ratingCount: 156,
            comments: [
                RecipeComment(author: "Ella", message: "Great brunch centerpiece."),
                RecipeComment(author: "Ben", message: "Swapped granola for toasted nuts.")
            ],
            tags: [.breakfast, .vegetarian, .minimalDishes, .quickUnder30],
            baseServings: 8,
            activeMinutesEstimate: 24,
            stepTimers: [RecipeStepTimerHint(stepIndex: 3, durationMinutes: 10)]
        ),
        RecipeRecord(
            id: "thai-inspired-noodle-bowl",
            title: "Thai-Inspired Noodle Bowl",
            summary: "Velvety coconut broth with herbs and quick-cook noodles.",
            previewSymbol: "fork.knife",
            ingredients: [
                "Rice noodles",
                "Coconut milk",
                "Red curry paste",
                "Snap peas",
                "Carrots",
                "Lime",
                "Cilantro"
            ],
            steps: [
                "Simmer coconut milk with curry paste.",
                "Add vegetables until bright.",
                "Cook noodles separately, combine gently.",
                "Finish with lime and herbs."
            ],
            averageRating: 4.7,
            ratingCount: 239,
            comments: [
                RecipeComment(author: "Mina", message: "Broth taste deepens next day."),
                RecipeComment(author: "Alex", message: "Added tofu for protein.")
            ],
            tags: [.dinner, .vegetarian, .quickUnder30],
            baseServings: 4,
            activeMinutesEstimate: 32,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 10)]
        ),
        RecipeRecord(
            id: "roasted-root-soup",
            title: "Roasted Root Soup",
            summary: "Velvety blend of roasted roots with warm spices.",
            previewSymbol: "drop.fill",
            ingredients: [
                "Carrots",
                "Sweet potato",
                "Garlic",
                "Vegetable stock",
                "Ginger",
                "Coconut cream",
                "Pumpkin seeds"
            ],
            steps: [
                "Roast roots until caramelized.",
                "Blend with stock and ginger.",
                "Finish with coconut cream swirl.",
                "Top with toasted seeds."
            ],
            averageRating: 4.6,
            ratingCount: 142,
            comments: [
                RecipeComment(author: "Ruth", message: "Freezes beautifully."),
                RecipeComment(author: "Ian", message: "Great with crusty bread.")
            ],
            tags: [.dinner, .vegetarian],
            baseServings: 8,
            activeMinutesEstimate: 58,
            stepTimers: [RecipeStepTimerHint(stepIndex: 0, durationMinutes: 32)]
        ),
        RecipeRecord(
            id: "caprese-skewers",
            title: "Caprese Skewers",
            summary: "Mini mozzarella, tomatoes, and basil with balsamic glaze.",
            previewSymbol: "circle.hexagongrid.fill",
            ingredients: [
                "Cherry tomatoes",
                "Mini mozzarella",
                "Basil",
                "Balsamic glaze",
                "Olive oil",
                "Flaky salt",
                "Skewers"
            ],
            steps: [
                "Thread tomato, cheese, and basil.",
                "Drizzle oil and glaze.",
                "Sprinkle flaky salt.",
                "Chill briefly before serving."
            ],
            averageRating: 4.3,
            ratingCount: 98,
            comments: [
                RecipeComment(author: "Sofia", message: "Perfect summer starter."),
                RecipeComment(author: "James", message: "Used pesto drizzle instead.")
            ],
            tags: [.vegetarian, .minimalDishes, .quickUnder30],
            baseServings: 12,
            activeMinutesEstimate: 22,
            stepTimers: [RecipeStepTimerHint(stepIndex: 3, durationMinutes: 12)]
        ),
        RecipeRecord(
            id: "spiced-chickpea-bowl",
            title: "Spiced Chickpea Bowl",
            summary: "Crispy chickpeas, grains, and cooling yogurt sauce.",
            previewSymbol: "circle.grid.cross.fill",
            ingredients: [
                "Chickpeas",
                "Cumin",
                "Smoked paprika",
                "Cooked quinoa",
                "Cucumber",
                "Greek yogurt",
                "Pickled onions"
            ],
            steps: [
                "Roast chickpeas with spices until crisp.",
                "Whisk yogurt with lemon and herbs.",
                "Layer grains, chickpeas, vegetables.",
                "Drizzle sauce and serve."
            ],
            averageRating: 4.8,
            ratingCount: 321,
            comments: [
                RecipeComment(author: "Tariq", message: "Lunch prep for the whole week."),
                RecipeComment(author: "Nina", message: "Added harissa for heat.")
            ],
            tags: [.dinner, .vegetarian, .minimalDishes],
            baseServings: 4,
            activeMinutesEstimate: 38,
            stepTimers: [RecipeStepTimerHint(stepIndex: 0, durationMinutes: 22)]
        ),
        RecipeRecord(
            id: "berry-chia-pudding",
            title: "Berry Chia Pudding",
            summary: "Overnight chia with jammy berries and vanilla.",
            previewSymbol: "sparkles",
            ingredients: [
                "Chia seeds",
                "Almond milk",
                "Maple syrup",
                "Vanilla",
                "Mixed berries",
                "Toasted almonds",
                "Orange zest"
            ],
            steps: [
                "Stir chia with milk, syrup, and vanilla.",
                "Refrigerate overnight.",
                "Warm berries into a quick compote.",
                "Layer pudding, compote, and nuts."
            ],
            averageRating: 4.5,
            ratingCount: 176,
            comments: [
                RecipeComment(author: "Yuki", message: "Great post-run snack."),
                RecipeComment(author: "Chris", message: "Used oat milk—still creamy.")
            ],
            tags: [.breakfast, .vegetarian, .minimalDishes, .quickUnder30],
            baseServings: 6,
            activeMinutesEstimate: 35,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 12)]
        ),
        RecipeRecord(
            id: "cast-iron-steak",
            title: "Cast-Iron Steak",
            summary: "Deep crust, butter baste, and resting juices.",
            previewSymbol: "triangle.fill",
            ingredients: [
                "Ribeye or strip",
                "Kosher salt",
                "Black pepper",
                "Neutral oil",
                "Butter",
                "Garlic",
                "Rosemary"
            ],
            steps: [
                "Season steak and rest to room temperature.",
                "Sear in ripping-hot pan.",
                "Baste with butter, garlic, herbs.",
                "Rest, slice, and serve."
            ],
            averageRating: 4.9,
            ratingCount: 502,
            comments: [
                RecipeComment(author: "Vince", message: "Crust rivals steakhouses."),
                RecipeComment(author: "Quinn", message: "Used compound butter at the end.")
            ],
            tags: [.dinner, .minimalDishes, .quickUnder30],
            baseServings: 4,
            activeMinutesEstimate: 28,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 8)]
        ),
        RecipeRecord(
            id: "garden-salad-jar",
            title: "Garden Salad Jar",
            summary: "Layered greens that stay crisp until lunch.",
            previewSymbol: "leaf.fill",
            ingredients: [
                "Radish",
                "Cucumber",
                "Cherry tomatoes",
                "Chickpeas",
                "Mixed greens",
                "Dijon vinaigrette",
                "Feta"
            ],
            steps: [
                "Pour dressing into jar first.",
                "Layer sturdy vegetables, then proteins.",
                "Top with greens and cheese.",
                "Shake before eating."
            ],
            averageRating: 4.2,
            ratingCount: 112,
            comments: [
                RecipeComment(author: "Parker", message: "No soggy leaves—finally."),
                RecipeComment(author: "Jules", message: "Great for office days.")
            ],
            tags: [.vegetarian, .minimalDishes, .quickUnder30],
            baseServings: 6,
            activeMinutesEstimate: 26,
            stepTimers: [RecipeStepTimerHint(stepIndex: 2, durationMinutes: 10)]
        ),
        RecipeRecord(
            id: "cocoa-oat-cookies",
            title: "Cocoa Oat Cookies",
            summary: "Chewy oats, cocoa, and coconut sugar crunch.",
            previewSymbol: "birthday.cake.fill",
            ingredients: [
                "Rolled oats",
                "Cocoa powder",
                "Coconut sugar",
                "Butter",
                "Egg",
                "Vanilla",
                "Dark chocolate chunks"
            ],
            steps: [
                "Cream butter and sugar.",
                "Beat in egg and vanilla.",
                "Fold oats, cocoa, and chocolate.",
                "Bake until edges are set."
            ],
            averageRating: 4.6,
            ratingCount: 241,
            comments: [
                RecipeComment(author: "Zoe", message: "Freezer dough works great."),
                RecipeComment(author: "Mark", message: "Added espresso powder—richer.")
            ],
            tags: [.vegetarian, .minimalDishes],
            baseServings: 36,
            activeMinutesEstimate: 42,
            stepTimers: [RecipeStepTimerHint(stepIndex: 3, durationMinutes: 12)]
        )
    ]
}
