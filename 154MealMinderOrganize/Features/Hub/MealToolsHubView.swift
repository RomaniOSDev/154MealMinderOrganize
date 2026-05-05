import SwiftUI

private enum MealPlanPane: String, CaseIterable, Identifiable {
    case groceries = "Groceries"
    case timers = "Timers"
    case week = "Week"

    var id: String { rawValue }
}

struct MealToolsHubView: View {
    @State private var pane: MealPlanPane = .groceries

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                Picker("", selection: $pane) {
                    ForEach(MealPlanPane.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.appPrimary)
                .padding(6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .appConvexPanel(cornerRadius: 18)
            .padding(.horizontal, 16)

            Group {
                switch pane {
                case .groceries:
                    GroceryListView()
                case .timers:
                    CookingTimersView()
                case .week:
                    WeeklyMealPlannerView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.26), value: pane)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
