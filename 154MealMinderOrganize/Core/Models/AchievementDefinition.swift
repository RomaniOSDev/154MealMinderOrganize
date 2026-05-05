import Foundation

struct AchievementMetrics {
    var recipesViewed: Int
    var favouritesAdded: Int
    var listsCompleted: Int
    var streakDays: Int
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let isUnlocked: (AchievementMetrics) -> Bool

    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_glance",
            title: "First Glance",
            subtitle: "Viewed your first recipe.",
            isUnlocked: { $0.recipesViewed >= 1 }
        ),
        AchievementDefinition(
            id: "recipe_explorer",
            title: "Recipe Explorer",
            subtitle: "Viewed ten recipes.",
            isUnlocked: { $0.recipesViewed >= 10 }
        ),
        AchievementDefinition(
            id: "fave_collector",
            title: "Fave Collector",
            subtitle: "Added five favorites.",
            isUnlocked: { $0.favouritesAdded >= 5 }
        ),
        AchievementDefinition(
            id: "shopping_pro",
            title: "Shopping Pro",
            subtitle: "Completed three grocery lists.",
            isUnlocked: { $0.listsCompleted >= 3 }
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            subtitle: "Reached 50 items.",
            isUnlocked: { $0.recipesViewed >= 50 }
        ),
        AchievementDefinition(
            id: "active_user",
            title: "Active User",
            subtitle: "Completed 10 sessions.",
            isUnlocked: { $0.listsCompleted >= 10 }
        ),
        AchievementDefinition(
            id: "dedicated_user",
            title: "Dedicated User",
            subtitle: "Completed 50 sessions.",
            isUnlocked: { $0.listsCompleted >= 50 }
        ),
        AchievementDefinition(
            id: "three_day_streak",
            title: "Three-Day Streak",
            subtitle: "Used the app 3 days in a row.",
            isUnlocked: { $0.streakDays >= 3 }
        )
    ]
}

extension AchievementDefinition: Equatable {
    static func == (lhs: AchievementDefinition, rhs: AchievementDefinition) -> Bool {
        lhs.id == rhs.id
    }
}
