import Combine
import Foundation

// Single source of truth for persisted preferences and feature data (bundle filename per spec).

@MainActor
final class MealPlannerStore: ObservableObject {
    private static let persistenceKey = "MealPlannerStore.snapshot.v1"

    private let defaults = UserDefaults.standard
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var hasSeenOnboarding = false

    private var persistEnabled = true

    fileprivate struct PersistedEnvelope: Equatable {
        var hasSeenOnboarding = false

        var recipesViewed = 0
        var favouritesAddedTotal = 0
        var listsCompleted = 0
        var streakDays = 0
        var lastActivityDayNormalized: Double?

        var totalSessionsCompleted = 0
        var totalMinutesUsed = 0

        var achievementsUnlockedDates: [String: String] = [:]

        var favoriteRecipeIDs: [String] = []
        var lastSearchedKeyword = ""
        var recentlyViewedRecipeIDs: [String] = []

        var groceryItems: [GroceryItem] = []
        var recentlyCompletedItemIDsString: [String] = []

        var cookingTimers: [PersistedCookingTimer] = []
        var lastUsedDurationSec = 300
        var userSettings: [String: String] = [:]

        var userRecipes: [UserRecipeRecord] = []

        var recipeIngredientScaleMultiplierByRecipeID: [String: Double] = [:]

        /// `recipeID` → (`step index string` → note text).
        var recipeStepNotesByRecipeAndStepIndex: [String: [String: String]] = [:]

        /// `WeekPlannerDay.rawValue` → `recipe id` (catalog or user).
        var weeklyMealAssignmentsByWeekdayKey: [String: String] = [:]

        static let empty = PersistedEnvelope()

        enum CodingKeys: String, CodingKey {
            case hasSeenOnboarding
            case recipesViewed
            case favouritesAddedTotal
            case listsCompleted
            case streakDays
            case lastActivityDayNormalized
            case totalSessionsCompleted
            case totalMinutesUsed
            case achievementsUnlockedDates
            case favoriteRecipeIDs
            case lastSearchedKeyword
            case recentlyViewedRecipeIDs
            case groceryItems
            case recentlyCompletedItemIDsString
            case cookingTimers
            case lastUsedDurationSec
            case userSettings
            case userRecipes
            case recipeIngredientScaleMultiplierByRecipeID
            case recipeStepNotesByRecipeAndStepIndex
            case weeklyMealAssignmentsByWeekdayKey
        }
    }

    private var envelope = PersistedEnvelope.empty

    @Published private(set) var favoriteRecipeIDs: [String] = []
    @Published private(set) var lastSearchedKeyword: String = ""
    @Published private(set) var recentlyViewedRecipeIDs: [String] = []
    @Published private(set) var groceryItems: [GroceryItem] = []
    @Published private(set) var recentlyCompletedItemIDs: [UUID] = []
    @Published private(set) var cookingTimers: [PersistedCookingTimer] = []
    @Published private(set) var lastUsedDurationSec: Int = 300
    @Published private(set) var userSettings: [String: String] = [:]

    @Published private(set) var recipesViewed: Int = 0
    @Published private(set) var favouritesAddedTotal: Int = 0
    @Published private(set) var listsCompleted: Int = 0
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var totalSessionsCompleted: Int = 0
    @Published private(set) var totalMinutesUsed: Int = 0
    @Published private(set) var achievementsUnlockedDates: [String: String] = [:]
    @Published private(set) var userRecipes: [UserRecipeRecord] = []
    @Published private(set) var recipeIngredientScaleMultiplierByRecipeID: [String: Double] = [:]
    @Published private(set) var recipeStepNotesByRecipeAndStepIndex: [String: [String: String]] = [:]
    @Published private(set) var weeklyMealAssignmentsByWeekdayKey: [String: String] = [:]

    init() {
        load()
        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadAfterReset()
            }
            .store(in: &cancellables)
    }

    var achievementMetrics: AchievementMetrics {
        AchievementMetrics(
            recipesViewed: recipesViewed,
            favouritesAdded: favouritesAddedTotal,
            listsCompleted: listsCompleted,
            streakDays: streakDays
        )
    }

    func achievementUnlockedDate(for id: String) -> Date? {
        guard let raw = achievementsUnlockedDates[id] else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    func isAchievementUnlocked(id: String) -> Bool {
        achievementsUnlockedDates[id] != nil
    }

    func markOnboardingFinished() {
        envelope.hasSeenOnboarding = true
        hasSeenOnboarding = true
        save(full: true)
        recordMeaningfulAction()
        evaluateAchievements()
    }

    func updateSearchKeyword(_ text: String) {
        envelope.lastSearchedKeyword = text
        lastSearchedKeyword = text
        save(full: true)
    }

    func recordRecipeViewed(id: String) {
        envelope.recipesViewed += 1
        recipesViewed = envelope.recipesViewed

        var recent = envelope.recentlyViewedRecipeIDs
        recent.removeAll { $0 == id }
        recent.insert(id, at: 0)
        if recent.count > 24 {
            recent = Array(recent.prefix(24))
        }
        envelope.recentlyViewedRecipeIDs = recent
        recentlyViewedRecipeIDs = recent

        recordMeaningfulAction()
        save(full: true)
        evaluateAchievements()
    }

    func upsertUserRecipe(_ recipe: UserRecipeRecord) {
        var list = envelope.userRecipes
        if let idx = list.firstIndex(where: { $0.id == recipe.id }) {
            list[idx] = recipe
        } else {
            list.append(recipe)
        }
        envelope.userRecipes = list
        userRecipes = list
        recordMeaningfulAction()
        save(full: true)
    }

    func deleteUserRecipe(id: String) {
        var list = envelope.userRecipes
        list.removeAll { $0.id == id }
        envelope.userRecipes = list
        userRecipes = list

        envelope.favoriteRecipeIDs.removeAll { $0 == id }
        favoriteRecipeIDs = envelope.favoriteRecipeIDs

        envelope.recentlyViewedRecipeIDs.removeAll { $0 == id }
        recentlyViewedRecipeIDs = envelope.recentlyViewedRecipeIDs

        pruneRecipeAssociations(forRecipeIDRemoving: id)
        UserRecipeImageStore.deleteImage(recipeID: id)
        save(full: true)
    }

    func normalizedIngredientMultiplier(forRecipeID recipeID: String) -> Double {
        let stored = envelope.recipeIngredientScaleMultiplierByRecipeID[recipeID]
        guard let stored, [0.5, 1.0, 2.0].contains(stored) else { return 1.0 }
        return stored
    }

    func setIngredientMultiplier(forRecipeID recipeID: String, multiplier: Double) {
        let clamped = [0.5, 1.0, 2.0].contains(multiplier) ? multiplier : 1.0
        var map = envelope.recipeIngredientScaleMultiplierByRecipeID
        if clamped == 1.0 {
            map.removeValue(forKey: recipeID)
        } else {
            map[recipeID] = clamped
        }
        envelope.recipeIngredientScaleMultiplierByRecipeID = map
        recipeIngredientScaleMultiplierByRecipeID = map
        save(full: true)
    }

    func stepNote(forRecipeID recipeID: String, stepIndex: Int) -> String {
        envelope.recipeStepNotesByRecipeAndStepIndex[recipeID]?["\(stepIndex)"] ?? ""
    }

    func setStepNote(forRecipeID recipeID: String, stepIndex: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var bucket = envelope.recipeStepNotesByRecipeAndStepIndex
        var inner = bucket[recipeID] ?? [:]
        let key = "\(stepIndex)"
        if trimmed.isEmpty {
            inner.removeValue(forKey: key)
        } else {
            inner[key] = trimmed
        }
        if inner.isEmpty {
            bucket.removeValue(forKey: recipeID)
        } else {
            bucket[recipeID] = inner
        }
        envelope.recipeStepNotesByRecipeAndStepIndex = bucket
        recipeStepNotesByRecipeAndStepIndex = bucket
        save(full: true)
    }

    func weeklyMealRecipeID(for day: WeekPlannerDay) -> String? {
        envelope.weeklyMealAssignmentsByWeekdayKey[day.rawValue]
    }

    func setWeeklyMealRecipe(_ recipeID: String?, for day: WeekPlannerDay) {
        var map = envelope.weeklyMealAssignmentsByWeekdayKey
        if let id = recipeID, id.isEmpty == false {
            map[day.rawValue] = id
        } else {
            map.removeValue(forKey: day.rawValue)
        }
        envelope.weeklyMealAssignmentsByWeekdayKey = map
        weeklyMealAssignmentsByWeekdayKey = map
        recordMeaningfulAction()
        save(full: true)
    }

    func addGroceryItemsFromIngredientLines(_ lines: [String]) {
        var items = envelope.groceryItems
        var existingLower = Set(items.map { $0.name.lowercased() })

        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !existingLower.contains(trimmed.lowercased()) else { continue }
            let category = GroceryIngredientCategoryGuess.category(forIngredientLine: trimmed)
            items.append(GroceryItem(name: trimmed, category: category))
            existingLower.insert(trimmed.lowercased())
        }

        envelope.groceryItems = items
        groceryItems = items
        recordMeaningfulAction()
        save(full: true)
    }

    func applyGrocerPreset(_ preset: BuiltInGroceryListPreset) {
        addGroceryItemsFromIngredientLines(preset.lines)
    }

    func toggleFavorite(recipeID: String) -> Bool {
        var favs = envelope.favoriteRecipeIDs
        if let index = favs.firstIndex(of: recipeID) {
            favs.remove(at: index)
            envelope.favoriteRecipeIDs = favs
            favoriteRecipeIDs = favs
            save(full: true)
            return false
        } else {
            favs.append(recipeID)
            envelope.favoriteRecipeIDs = favs
            favoriteRecipeIDs = favs
            envelope.favouritesAddedTotal += 1
            favouritesAddedTotal = envelope.favouritesAddedTotal
            recordMeaningfulAction()
            save(full: true)
            evaluateAchievements()
            return true
        }
    }

    func isFavorite(recipeID: String) -> Bool {
        favoriteRecipeIDs.contains(recipeID)
    }

    func addGroceryItem(name: String, category: GroceryCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = envelope.groceryItems
        items.append(GroceryItem(name: trimmed, category: category))
        envelope.groceryItems = items
        groceryItems = items
        recordMeaningfulAction()
        save(full: true)
    }

    func updateGroceryItem(id: UUID, name: String, category: GroceryCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = envelope.groceryItems
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].name = trimmed
        items[index].category = category
        envelope.groceryItems = items
        groceryItems = items
        save(full: true)
    }

    func toggleGroceryCompleted(id: UUID, at date: Date) {
        var items = envelope.groceryItems
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].completed.toggle()
        envelope.groceryItems = items
        groceryItems = items

        var recent = envelope.recentlyCompletedItemIDsString
        if items[index].completed {
            recent.removeAll { $0 == id.uuidString }
            recent.insert(id.uuidString, at: 0)
            if recent.count > 30 {
                recent = Array(recent.prefix(30))
            }
        } else {
            recent.removeAll { $0 == id.uuidString }
        }
        envelope.recentlyCompletedItemIDsString = recent
        recentlyCompletedItemIDs = recent.compactMap(UUID.init)

        recordMeaningfulAction()
        save(full: true)
    }

    func removeGroceryItem(id: UUID) {
        var items = envelope.groceryItems
        items.removeAll { $0.id == id }
        envelope.groceryItems = items
        groceryItems = items
        save(full: true)
    }

    func completeGroceryShoppingSession() {
        let hadItems = !envelope.groceryItems.isEmpty
        let allDone = envelope.groceryItems.allSatisfy(\.completed)
        guard hadItems, allDone else { return }

        envelope.groceryItems = []
        groceryItems = []
        envelope.listsCompleted += 1
        listsCompleted = envelope.listsCompleted
        envelope.totalSessionsCompleted += 1
        totalSessionsCompleted = envelope.totalSessionsCompleted
        envelope.totalMinutesUsed += 15
        totalMinutesUsed = envelope.totalMinutesUsed
        recordMeaningfulAction()
        save(full: true)
        evaluateAchievements()
    }

    func addCookingTimer(
        dishName: String,
        durationSeconds: Int,
        from date: Date,
        linkedRecipeID: String? = nil,
        linkedStepIndex: Int? = nil
    ) {
        let trimmed = dishName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let seconds = max(10, durationSeconds)
        var timers = envelope.cookingTimers
        var timer = PersistedCookingTimer(
            dishName: trimmed,
            linkedRecipeID: linkedRecipeID,
            linkedStepIndex: linkedStepIndex
        )
        timer.reset(durationSeconds: seconds, from: date)
        timers.append(timer)
        envelope.cookingTimers = timers
        cookingTimers = timers
        envelope.lastUsedDurationSec = seconds
        lastUsedDurationSec = seconds
        recordMeaningfulAction()
        save(full: true)
    }

    func togglePauseCookingTimer(id: UUID, at date: Date) {
        var timers = envelope.cookingTimers
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].toggleUserPause(at: date)
        envelope.cookingTimers = timers
        cookingTimers = timers
        save(full: true)
    }

    func synchronizeCookingTimersForSceneActivation(_ isActive: Bool, date: Date) {
        var timers = envelope.cookingTimers
        if isActive {
            for index in timers.indices {
                timers[index].resumeIfIdleHeld(at: date)
            }
        } else {
            for index in timers.indices {
                timers[index].freezeIfRunningForIdle(at: date)
            }
        }
        envelope.cookingTimers = timers
        cookingTimers = timers
        save(full: true)
    }

    func resetCookingTimer(id: UUID, durationSeconds: Int, from date: Date) {
        var timers = envelope.cookingTimers
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        let seconds = max(10, durationSeconds)
        timers[index].reset(durationSeconds: seconds, from: date)
        envelope.cookingTimers = timers
        cookingTimers = timers
        recordMeaningfulAction()
        save(full: true)
    }

    func removeCookingTimer(id: UUID) {
        var timers = envelope.cookingTimers
        timers.removeAll { $0.id == id }
        envelope.cookingTimers = timers
        cookingTimers = timers
        save(full: true)
    }

    func finishCookingTimer(id: UUID) {
        var timers = envelope.cookingTimers
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        let total = max(60, timers[index].totalDurationSeconds)
        timers.remove(at: index)
        envelope.cookingTimers = timers
        cookingTimers = timers

        let minutes = max(1, Int(ceil(Double(total) / 60.0)))
        envelope.totalMinutesUsed += minutes
        totalMinutesUsed = envelope.totalMinutesUsed
        envelope.totalSessionsCompleted += 1
        totalSessionsCompleted = envelope.totalSessionsCompleted

        recordMeaningfulAction()
        save(full: true)
        evaluateAchievements()
    }

    func settingsValue(for key: String) -> String? {
        userSettings[key]
    }

    func setSettingsValue(_ value: String, for key: String) {
        var settings = envelope.userSettings
        settings[key] = value
        envelope.userSettings = settings
        userSettings = settings
        save(full: true)
    }

    func resetAllData() {
        persistEnabled = false
        UserRecipeImageStore.deleteAllStoredImages()
        defaults.removeObject(forKey: Self.persistenceKey)
        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
        }
        envelope = .empty
        rebuildPublishedCaches(from: envelope)
        persistEnabled = true
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func reloadAfterReset() {
        load()
    }

    private func load() {
        persistEnabled = false
        if let data = defaults.data(forKey: Self.persistenceKey),
           let decoded = try? JSONDecoder().decode(PersistedEnvelope.self, from: data) {
            envelope = decoded
        } else {
            envelope = .empty
        }
        rebuildPublishedCaches(from: envelope)
        persistEnabled = true
        evaluateAchievements()
    }

    private func save(full: Bool) {
        guard persistEnabled else { return }
        if full {
            do {
                let data = try JSONEncoder().encode(envelope)
                defaults.set(data, forKey: Self.persistenceKey)
            } catch {
                // Encoding failure is ignored; app continues with in-memory state.
            }
        }
    }

    private func pruneRecipeAssociations(forRecipeIDRemoving recipeID: String) {
        var scale = envelope.recipeIngredientScaleMultiplierByRecipeID
        scale.removeValue(forKey: recipeID)
        envelope.recipeIngredientScaleMultiplierByRecipeID = scale
        recipeIngredientScaleMultiplierByRecipeID = scale

        var notes = envelope.recipeStepNotesByRecipeAndStepIndex
        notes.removeValue(forKey: recipeID)
        envelope.recipeStepNotesByRecipeAndStepIndex = notes
        recipeStepNotesByRecipeAndStepIndex = notes

        var weekly = envelope.weeklyMealAssignmentsByWeekdayKey
        for (key, value) in weekly where value == recipeID {
            weekly.removeValue(forKey: key)
        }
        envelope.weeklyMealAssignmentsByWeekdayKey = weekly
        weeklyMealAssignmentsByWeekdayKey = weekly
    }

    private func rebuildPublishedCaches(from env: PersistedEnvelope) {
        hasSeenOnboarding = env.hasSeenOnboarding
        recipesViewed = env.recipesViewed
        favouritesAddedTotal = env.favouritesAddedTotal
        listsCompleted = env.listsCompleted
        streakDays = env.streakDays
        totalSessionsCompleted = env.totalSessionsCompleted
        totalMinutesUsed = env.totalMinutesUsed
        achievementsUnlockedDates = env.achievementsUnlockedDates

        favoriteRecipeIDs = env.favoriteRecipeIDs
        lastSearchedKeyword = env.lastSearchedKeyword
        recentlyViewedRecipeIDs = env.recentlyViewedRecipeIDs
        groceryItems = env.groceryItems
        recentlyCompletedItemIDs = env.recentlyCompletedItemIDsString.compactMap(UUID.init)
        cookingTimers = env.cookingTimers
        lastUsedDurationSec = env.lastUsedDurationSec
        userSettings = env.userSettings
        userRecipes = env.userRecipes
        recipeIngredientScaleMultiplierByRecipeID = env.recipeIngredientScaleMultiplierByRecipeID
        recipeStepNotesByRecipeAndStepIndex = env.recipeStepNotesByRecipeAndStepIndex
        weeklyMealAssignmentsByWeekdayKey = env.weeklyMealAssignmentsByWeekdayKey
    }

    private func recordMeaningfulAction(now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayStamp = today.timeIntervalSince1970

        if let last = envelope.lastActivityDayNormalized {
            let lastDate = Date(timeIntervalSince1970: last)
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                return
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
            if let yesterday, lastDay == yesterday {
                envelope.streakDays += 1
            } else {
                envelope.streakDays = 1
            }
        } else {
            envelope.streakDays = 1
        }

        envelope.lastActivityDayNormalized = todayStamp
        streakDays = envelope.streakDays
    }

    func evaluateAchievements() {
        let metrics = achievementMetrics
        let formatter = ISO8601DateFormatter()
        var changed = false
        for definition in AchievementDefinition.all {
            if envelope.achievementsUnlockedDates[definition.id] != nil {
                continue
            }
            if definition.isUnlocked(metrics) {
                envelope.achievementsUnlockedDates[definition.id] = formatter.string(from: Date())
                changed = true
                NotificationCenter.default.post(
                    name: .achievementUnlocked,
                    object: nil,
                    userInfo: ["title": definition.title]
                )
                AppHaptics.achievementUnlocked()
            }
        }
        if changed {
            achievementsUnlockedDates = envelope.achievementsUnlockedDates
            save(full: true)
        }
    }
}

extension MealPlannerStore.PersistedEnvelope: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        recipesViewed = try c.decodeIfPresent(Int.self, forKey: .recipesViewed) ?? 0
        favouritesAddedTotal = try c.decodeIfPresent(Int.self, forKey: .favouritesAddedTotal) ?? 0
        listsCompleted = try c.decodeIfPresent(Int.self, forKey: .listsCompleted) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActivityDayNormalized = try c.decodeIfPresent(Double.self, forKey: .lastActivityDayNormalized)
        totalSessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .totalSessionsCompleted) ?? 0
        totalMinutesUsed = try c.decodeIfPresent(Int.self, forKey: .totalMinutesUsed) ?? 0
        achievementsUnlockedDates =
            try c.decodeIfPresent([String: String].self, forKey: .achievementsUnlockedDates) ?? [:]
        favoriteRecipeIDs = try c.decodeIfPresent([String].self, forKey: .favoriteRecipeIDs) ?? []
        lastSearchedKeyword = try c.decodeIfPresent(String.self, forKey: .lastSearchedKeyword) ?? ""
        recentlyViewedRecipeIDs =
            try c.decodeIfPresent([String].self, forKey: .recentlyViewedRecipeIDs) ?? []
        groceryItems = try c.decodeIfPresent([GroceryItem].self, forKey: .groceryItems) ?? []
        recentlyCompletedItemIDsString =
            try c.decodeIfPresent([String].self, forKey: .recentlyCompletedItemIDsString) ?? []
        cookingTimers =
            try c.decodeIfPresent([PersistedCookingTimer].self, forKey: .cookingTimers) ?? []
        lastUsedDurationSec = try c.decodeIfPresent(Int.self, forKey: .lastUsedDurationSec) ?? 300
        userSettings = try c.decodeIfPresent([String: String].self, forKey: .userSettings) ?? [:]
        userRecipes =
            try c.decodeIfPresent([UserRecipeRecord].self, forKey: .userRecipes) ?? []
        recipeIngredientScaleMultiplierByRecipeID =
            try c.decodeIfPresent([String: Double].self, forKey: .recipeIngredientScaleMultiplierByRecipeID) ?? [:]
        recipeStepNotesByRecipeAndStepIndex =
            try c.decodeIfPresent([String: [String: String]].self, forKey: .recipeStepNotesByRecipeAndStepIndex) ?? [:]
        weeklyMealAssignmentsByWeekdayKey =
            try c.decodeIfPresent([String: String].self, forKey: .weeklyMealAssignmentsByWeekdayKey) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(hasSeenOnboarding, forKey: .hasSeenOnboarding)
        try c.encode(recipesViewed, forKey: .recipesViewed)
        try c.encode(favouritesAddedTotal, forKey: .favouritesAddedTotal)
        try c.encode(listsCompleted, forKey: .listsCompleted)
        try c.encode(streakDays, forKey: .streakDays)
        try c.encodeIfPresent(lastActivityDayNormalized, forKey: .lastActivityDayNormalized)
        try c.encode(totalSessionsCompleted, forKey: .totalSessionsCompleted)
        try c.encode(totalMinutesUsed, forKey: .totalMinutesUsed)
        try c.encode(achievementsUnlockedDates, forKey: .achievementsUnlockedDates)
        try c.encode(favoriteRecipeIDs, forKey: .favoriteRecipeIDs)
        try c.encode(lastSearchedKeyword, forKey: .lastSearchedKeyword)
        try c.encode(recentlyViewedRecipeIDs, forKey: .recentlyViewedRecipeIDs)
        try c.encode(groceryItems, forKey: .groceryItems)
        try c.encode(recentlyCompletedItemIDsString, forKey: .recentlyCompletedItemIDsString)
        try c.encode(cookingTimers, forKey: .cookingTimers)
        try c.encode(lastUsedDurationSec, forKey: .lastUsedDurationSec)
        try c.encode(userSettings, forKey: .userSettings)
        try c.encode(userRecipes, forKey: .userRecipes)
        try c.encode(recipeIngredientScaleMultiplierByRecipeID, forKey: .recipeIngredientScaleMultiplierByRecipeID)
        try c.encode(recipeStepNotesByRecipeAndStepIndex, forKey: .recipeStepNotesByRecipeAndStepIndex)
        try c.encode(weeklyMealAssignmentsByWeekdayKey, forKey: .weeklyMealAssignmentsByWeekdayKey)
    }
}