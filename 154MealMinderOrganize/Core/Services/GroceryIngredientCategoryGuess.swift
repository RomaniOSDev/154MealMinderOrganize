import Foundation

enum GroceryIngredientCategoryGuess {
    private static func lower(_ s: String) -> String {
        s.lowercased()
    }

    static func category(forIngredientLine line: String) -> GroceryCategory {
        let s = lower(line)

        func match(_ needles: String...) -> Bool {
            needles.contains { s.contains($0) }
        }

        if match("milk", "cream", "yogurt", "cheese", "butter", "mozzarella", "feta") {
            return .dairy
        }
        if match("beef", "pork", "chicken", "turkey", "salmon", "fish", "steak", "egg ", "egg,", "ribs", "shrimp") {
            return .protein
        }
        if match("bread", "tortilla", "bagel", "croissant", "bun ") {
            return .bakery
        }
        if match("frozen", "ice cream") {
            return .frozen
        }
        if match("coffee", "tea ", " juice", "soda", "water", "wine", "beer") {
            return .beverages
        }
        if match(
            "lettuce", "spinach", "tomato", "onion", "garlic", "pepper",
            "potato", "carrot", "cucumber", "lemon", "lime", "herb",
            "basil", "cilantro", "dill", "apple", "berry", "mushroom",
            "greens", "radish", "avocado", "ginger"
        ) {
            return .produce
        }

        return .pantry
    }
}
