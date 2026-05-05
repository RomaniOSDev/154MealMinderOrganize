import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let item: RecipeListItem
    @EnvironmentObject private var store: MealPlannerStore
    @Environment(\.dismiss) private var dismiss
    @State private var ratingsExpanded = false

    @State private var heroCover: UIImage?
    @State private var editorPresentation: RecipeEditorPresentation?
    @State private var deleteConfirmation = false

    @State private var cookingModePresented = false
    @State private var groceryImporterPresented = false

    private var displayItem: RecipeListItem {
        guard case let .user(u) = item.payload else { return item }
        guard let refreshed = store.userRecipes.first(where: { $0.id == u.id }) else { return item }
        return RecipeListItem(user: refreshed)
    }

    private var multiplier: Double {
        store.normalizedIngredientMultiplier(forRecipeID: displayItem.id)
    }

    private var scaledIngredients: [String] {
        displayItem.scaledIngredientLines(multiplier: multiplier)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    favouritesButton

                    tagRibbon

                    scalingControl

                    timeAndServingsRow

                    plannerQuickAssign

                    actionStrip

                    if displayItem.isUserOwned {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill.viewfinder")
                                .foregroundStyle(Color.appAccent)
                                .font(.title3.weight(.semibold))

                            Text("Your saved recipe edits here stay on-device.")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appElevatedCard(cornerRadius: 16, tier: .subtle)
                    }

                    ingredientSection

                    stepsSection

                    if displayItem.builtinRecipe != nil {
                        DisclosureGroup(isExpanded: $ratingsExpanded) {
                            ratingsBody
                                .padding(.top, 8)
                        } label: {
                            Label("Community Ratings & Comments", systemImage: "text.bubble.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(18)
                        .appElevatedCard(cornerRadius: 18)
                    }

                    Color.clear.frame(height: 30)
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            .toolbar {
                if displayItem.isUserOwned {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            AppHaptics.lightTap()
                            if let snapshot = displayItem.userRecord() {
                                editorPresentation = .edit(snapshot)
                            }
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        .accessibilityHint("Opens the recipe editor")

                        Button(role: .destructive) {
                            deleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppHaptics.lightTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.appAccent, Color.appSurface)
                            .font(.system(size: 26, weight: .semibold))
                    }
                    .accessibilityLabel("Close")
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .screenBackground()
        .onAppear {
            reloadHeroImage()
        }
        .onChange(of: displayItem.tileRefreshToken) { _, _ in
            reloadHeroImage()
        }
        .sheet(item: $editorPresentation) { presentation in
            RecipeEditorView(presentation: presentation)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $cookingModePresented) {
            CookingWalkthroughView(recipe: displayItem)
                .environmentObject(store)
        }
        .sheet(isPresented: $groceryImporterPresented) {
            RecipeIngredientGrocerySheet(recipe: displayItem, lines: scaledIngredients)
                .environmentObject(store)
                .presentationDetents([.large])
                .sheetPresentationChrome()
        }
        .alert("Delete recipe?", isPresented: $deleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let id = displayItem.userRecord()?.id {
                    AppHaptics.mediumImpact()
                    store.deleteUserRecipe(id: id)
                    dismiss()
                }
            }
        } message: {
            Text("This removes the recipe and any stored photo permanently from this device.")
        }
    }

    private var tagRibbon: some View {
        Group {
            if displayItem.embeddedTags.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(displayItem.embeddedTags.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { tag in
                            Text(tag.filterLabel)
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Color.appBackground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appPrimary.opacity(0.88))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appElevatedCard(cornerRadius: 16, tier: .subtle)
            }
        }
    }

    private var scalingControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredient scale")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Ingredient lines scale from the written totals for \(displayItem.baseServingsCount) servings.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Scale", selection: Binding(
                get: { multiplier },
                set: { store.setIngredientMultiplier(forRecipeID: displayItem.id, multiplier: $0) }
            )) {
                Text("×½").tag(0.5)
                Text("×1").tag(1.0)
                Text("×2").tag(2.0)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 18)
    }

    private var timeAndServingsRow: some View {
        HStack(spacing: 14) {
            Label("Serves \(displayItem.baseServingsCount)", systemImage: "person.3.fill")
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            if let minutes = displayItem.estimatedActiveMinutes {
                Label("~\(minutes) min", systemImage: "clock.fill")
                    .foregroundStyle(Color.appAccent)
            }
        }
        .font(.caption.weight(.heavy))
        .padding(.horizontal, 4)
    }

    private var plannerQuickAssign: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly plan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WeekPlannerDay.allCases) { day in
                        Button {
                            AppHaptics.lightTap()
                            store.setWeeklyMealRecipe(displayItem.id, for: day)
                            AppHaptics.successNotice()
                        } label: {
                            Text(day.shortTitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(
                                    store.weeklyMealRecipeID(for: day) == displayItem.id ? Color.appBackground : Color.appTextPrimary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Group {
                                        if store.weeklyMealRecipeID(for: day) == displayItem.id {
                                            Capsule()
                                                .fill(AppVisualGradients.primaryButton)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                                )
                                        } else {
                                            Capsule()
                                                .fill(AppVisualGradients.mutedChipFill)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color.appPrimary.opacity(0.22),
                                                                    Color.appAccent.opacity(0.08)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 0.85
                                                        )
                                                )
                                                .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
                                        }
                                    }
                                )
                                .clipShape(Capsule())
                        }
                        .accessibilityHint("Pins this dish to \(day.shortTitle)")
                    }
                }
            }

            Button {
                AppHaptics.lightTap()
                for day in WeekPlannerDay.allCases {
                    if store.weeklyMealRecipeID(for: day) == displayItem.id {
                        store.setWeeklyMealRecipe(nil, for: day)
                    }
                }
            } label: {
                Label("Remove from all weekdays", systemImage: "calendar.badge.minus")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .opacity(WeekPlannerDay.allCases.contains(where: { store.weeklyMealRecipeID(for: $0) == displayItem.id }) ? 1 : 0.35)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 18)
    }

    private var actionStrip: some View {
        HStack(spacing: 12) {
            Button {
                AppHaptics.mediumImpact()
                cookingModePresented = true
            } label: {
                Label("Cook mode", systemImage: "hands.sparkles.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppPrimaryRoundedButtonStyle())

            Button {
                AppHaptics.lightTap()
                groceryImporterPresented = true
            } label: {
                Label("Prep list+", systemImage: "cart.badge.plus")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.appBackground)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppVisualGradients.accentSecondaryCTA)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.32), radius: 14, x: 0, y: 9)
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 10, x: 0, y: 6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .minimumScaleFactor(0.74)
        .lineLimit(1)
    }

    private func reloadHeroImage() {
        heroCover = nil
        guard case let .user(u) = displayItem.payload, u.hasCoverImage else {
            return
        }
        heroCover = UserRecipeImageStore.load(recipeID: u.id)
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Text("Scaled quantities stay private on this phone.")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)

            ForEach(Array(scaledIngredients.enumerated()), id: \.offset) { _, line in
                Label {
                    Text(line)
                        .foregroundStyle(Color.appTextSecondary)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "leaf")
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 20)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps & notes")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            ForEach(Array(displayItem.stepsList.enumerated()), id: \.offset) { index, step in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appBackground)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appAccent.opacity(0.95), Color.appPrimary.opacity(0.82)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 3)
                            )

                        Text(step)
                            .foregroundStyle(Color.appTextSecondary)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let hint = displayItem.timerHint(forStepIndex: index) {
                        Button {
                            AppHaptics.mediumImpact()
                            let dish = "\(displayItem.title) • Step \(index + 1)"
                            store.addCookingTimer(
                                dishName: dish,
                                durationSeconds: max(60, hint.durationMinutes * 60),
                                from: Date(),
                                linkedRecipeID: displayItem.id,
                                linkedStepIndex: index
                            )
                        } label: {
                            Label(
                                "Start preset \(hint.durationMinutes) minute timer",
                                systemImage: "timer.circle.fill"
                            )
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your note")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.appTextSecondary)

                        TextField(
                            "",
                            text: Binding(
                                get: { store.stepNote(forRecipeID: displayItem.id, stepIndex: index) },
                                set: {
                                    store.setStepNote(forRecipeID: displayItem.id, stepIndex: index, text: $0)
                                }
                            ),
                            axis: .vertical
                        )
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2 ... 4)
                        .textInputAutocapitalization(.sentences)

                        Text("Ideas like “my oven runs cool” appear only here.")
                            .font(.caption2)
                            .foregroundStyle(Color.appTextSecondary.opacity(0.88))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appInsetWell(cornerRadius: 12)

                    Divider()
                        .overlay(Color.appTextSecondary.opacity(0.35))
                        .padding(.vertical, 2)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .appElevatedCard(cornerRadius: 20)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.48),
                            Color.appPrimary.opacity(0.54),
                            Color.appBackground.opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if displayItem.isUserOwned, let cover = heroCover {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Image(systemName: displayItem.previewSymbolName)
                    .font(.system(size: 120, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary.opacity(0.94))
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(displayItem.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                Text(displayItem.summary.isEmpty ? " " : displayItem.summary)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.appBackground.opacity(0.1), Color.appBackground.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.appPrimary.opacity(0.42),
                            Color.appAccent.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.35
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 26, x: 0, y: 18)
        .shadow(color: Color.appAccent.opacity(0.16), radius: 22, x: 0, y: 12)
    }

    private var favouritesButton: some View {
        Button {
            AppHaptics.mediumImpact()
            let added = store.toggleFavorite(recipeID: displayItem.id)
            if added {
                AppHaptics.successNotice()
                SystemSounds.play(SystemSounds.favoriteAdded)
                SystemSounds.play(SystemSounds.successPing)
            }
        } label: {
            Label(
                store.isFavorite(recipeID: displayItem.id) ? "Favourite Saved" : "Mark as Favourite",
                systemImage: store.isFavorite(recipeID: displayItem.id) ? "heart.fill" : "heart"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(AppPrimaryRoundedButtonStyle())
    }

    @ViewBuilder
    private var ratingsBody: some View {
        if let recipe = displayItem.builtinRecipe {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Text(String(format: "%.1f", recipe.averageRating))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.appPrimary)

                    Text("Average from \(recipe.ratingCount) home cooks.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)

                    Spacer(minLength: 0)
                }

                Divider().background(Color.appTextSecondary.opacity(0.35))

                VStack(spacing: 16) {
                    ForEach(recipe.comments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(comment.author)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                            Text(comment.message)
                                .foregroundStyle(Color.appTextSecondary)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .foregroundStyle(Color.appTextPrimary)
        }
    }

}
