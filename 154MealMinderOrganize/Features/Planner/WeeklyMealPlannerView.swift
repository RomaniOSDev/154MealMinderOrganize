import SwiftUI

struct WeeklyMealPlannerView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @State private var assigningDay: WeekPlannerDay?

    private var combinedRecipes: [RecipeListItem] {
        let sortedUsers = store.userRecipes.sorted { $0.updatedAt > $1.updatedAt }
            .map(RecipeListItem.init(user:))
        let builtins = RecipeCatalog.all.map { RecipeListItem(builtin: $0) }
        return sortedUsers + builtins
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Assign mains for each weekday. Everything saves only on-device.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Section("This week") {
                    ForEach(WeekPlannerDay.allCases) { day in
                        let assigned = store.weeklyMealRecipeID(for: day)
                        Button {
                            AppHaptics.lightTap()
                            assigningDay = day
                        } label: {
                            HStack {
                                Text(day.shortTitle)
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .frame(width: 48, alignment: .leading)

                                VStack(alignment: .leading, spacing: 4) {
                                    if let assigned, assigned.isEmpty == false {
                                        Text(RecipeResolution.title(recipeID: assigned, store: store))
                                            .foregroundStyle(Color.appTextSecondary)
                                    } else {
                                        Text("No recipe pinned")
                                            .foregroundStyle(Color.appTextSecondary.opacity(0.74))
                                            .italic()
                                    }
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(Color.appAccent)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Weekly plan")
            .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 56)
        }
        .sheet(item: $assigningDay) { dayProxy in
            WeeklyRecipePickerSheet(
                day: dayProxy,
                options: combinedRecipes,
                dismiss: {
                    assigningDay = nil
                }
            )
            .environmentObject(store)
            .presentationDetents([.large])
            .sheetPresentationChrome()
        }
    }
}

private struct WeeklyRecipePickerSheet: View {
    let day: WeekPlannerDay
    let options: [RecipeListItem]
    let dismiss: () -> Void

    @EnvironmentObject private var store: MealPlannerStore
    @State private var keyword = ""

    private var filtered: [RecipeListItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return options }
        return options.filter { $0.searchBlob().contains(trimmed.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(
                        "",
                        text: $keyword,
                        prompt: Text("Search recipes").foregroundStyle(Color.appTextSecondary)
                    )
                    .foregroundStyle(Color.appTextPrimary)

                    Button(role: .destructive) {
                        store.setWeeklyMealRecipe(nil, for: day)
                        dismiss()
                    } label: {
                        Label("Clear \(day.shortTitle)", systemImage: "trash")
                    }
                    .foregroundStyle(Color.appAccent)
                }

                Section("Matches") {
                    ForEach(filtered) { candidate in
                        Button {
                            store.setWeeklyMealRecipe(candidate.id, for: day)
                            AppHaptics.successNotice()
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(candidate.title)
                                    .foregroundStyle(Color.appTextPrimary)

                                Text(candidate.summary)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("\(day.shortTitle)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
        }
        .themedGroupedSurface()
    }
}
