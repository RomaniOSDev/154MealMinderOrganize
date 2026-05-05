import Foundation

enum BuiltInGroceryListPreset: String, CaseIterable, Identifiable {
    case typicalWeeknight
    case picnicBasket

    var id: String { rawValue }

    var title: String {
        switch self {
        case .typicalWeeknight: return "Typical week staples"
        case .picnicBasket: return "Picnic basket starter"
        }
    }

    var detail: String {
        switch self {
        case .typicalWeeknight:
            return "Mix of produce, pantry, and dairy staples for weekday cooking."
        case .picnicBasket:
            return "Portable fillers for an outdoor picnic or park lunch."
        }
    }

    var lines: [String] {
        switch self {
        case .typicalWeeknight:
            return [
                "Mixed salad greens",
                "Cherry tomatoes",
                "Cucumber",
                "Greek yogurt",
                "Eggs",
                "Wholegrain bread",
                "Rolled oats",
                "Almond milk",
                "Chicken thighs",
                "Block cheddar",
                "Brown rice",
                "Olive oil",
                "Frozen peas",
                "Bananas",
                "Herb tea bags"
            ]
        case .picnicBasket:
            return [
                "Whole wheat wraps",
                "Sliced deli turkey",
                "Hummus",
                "Baby carrots",
                "Grapes",
                "Sparkling water",
                "Dark chocolate squares",
                "Paper napkins",
                "Ice packs"
            ]
        }
    }
}
