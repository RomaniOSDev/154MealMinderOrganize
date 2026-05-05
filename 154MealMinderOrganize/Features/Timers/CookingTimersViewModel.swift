import Combine
import SwiftUI

@MainActor
final class CookingTimersViewModel: ObservableObject {
    @Published var isPresentingAdd = false
    @Published var draftName = ""
    @Published var draftDurationMinutes: Double = 5
    @Published var expandedTimerIDs: Set<UUID> = []
    @Published var shakeToken: CGFloat = 0
    @Published var showValidation = false

    func beginAdd(store: MealPlannerStore) {
        draftName = ""
        draftDurationMinutes = Double(max(1, store.lastUsedDurationSec)) / 60.0
        showValidation = false
        shakeToken = 0
        isPresentingAdd = true
    }
}
