import SwiftUI
import UIKit

private struct CookingLogoBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppVisualGradients.mutedChipFill)
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.appPrimary)
        }
        .frame(width: 52, height: 52)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppVisualGradients.cardBorder.opacity(0.92), lineWidth: 1.1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 6)
    }
}

private struct RecipeTile: View {
    let item: RecipeListItem
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onDeleteUserRecipe: ((_ id: String) -> Void)?

    @EnvironmentObject private var store: MealPlannerStore
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                ZStack {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.appPrimary.opacity(0.12))

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appPrimary.opacity(0.45),
                                        Color.appAccent.opacity(0.55)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(26)

                        Image(systemName: item.previewSymbolName)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appTextPrimary.opacity(0.95), Color.appPrimary)
                            .font(.system(size: 42, weight: .semibold))
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if item.isUserOwned {
                    Text("YOURS")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.appAccent.opacity(0.92)))
                        .padding(10)
                }
            }

            Text(item.title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(item.summary.isEmpty ? " " : item.summary)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary.opacity(item.summary.isEmpty ? 0.35 : 1))
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                AppHaptics.lightTap()
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isFavorite ? Color.appPrimary : Color.appTextSecondary.opacity(0.9))
                    .padding(10)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .frame(minWidth: 44, minHeight: 44)
            .padding(4)
            .appElevatedCard(cornerRadius: 14, tier: .subtle)
        }
        .contextMenu {
            Button {
                AppHaptics.mediumImpact()
                onToggleFavorite()
            } label: {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.slash" : "heart.fill"
                )
            }

            Button {
                AppHaptics.lightTap()
                onSelect()
            } label: {
                Label("View Details", systemImage: "text.magnifyingglass")
            }

            if item.isUserOwned, let deleteAction = onDeleteUserRecipe {
                Divider()
                Button(role: .destructive) {
                    AppHaptics.mediumImpact()
                    deleteAction(item.id)
                } label: {
                    Label("Delete Recipe", systemImage: "trash")
                }
            }
        }
        .padding(12)
        .appElevatedCard(cornerRadius: 20, tier: .standard)
        .onAppear {
            refreshThumbnail()
        }
        .onChange(of: item.tileRefreshToken) { _, _ in
            refreshThumbnail()
        }
        .onChange(of: store.userRecipes) { _, _ in
            refreshThumbnail()
        }
    }

    private func refreshThumbnail() {
        guard let user = item.userRecord(), user.hasCoverImage else {
            thumbnail = nil
            return
        }
        thumbnail = UserRecipeImageStore.load(recipeID: user.id)
    }
}

private struct RecipeLibraryFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .appFABGradientBackdrop()
        .accessibilityLabel("New recipe")
    }
}

struct RecipeExplorerView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @StateObject private var viewModel = RecipeExplorerViewModel()
    @State private var selectedItem: RecipeListItem?
    @State private var recipeEditorPresentation: RecipeEditorPresentation?
    @State private var activeRecipeTagFilters = Set<RecipeTag>()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredItems: [RecipeListItem] {
        viewModel.filteredRecipeItems(
            userRecipes: store.userRecipes,
            favorites: Set(store.favoriteRecipeIDs),
            activeRecipeTags: activeRecipeTagFilters
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        modePicker
                        recipeTagChipsRow

                        Group {
                            if viewModel.filterMode == .favorites, store.favoriteRecipeIDs.isEmpty {
                                EmptyFavoritesRecipesView()
                            } else if filteredItems.isEmpty {
                                EmptySearchRecipesView()
                            } else if viewModel.filterMode == .browse, store.favoriteRecipeIDs.isEmpty {
                                GuidedBrowseHint()
                                    .padding(.horizontal, -4)
                            }

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredItems) { item in
                                    RecipeTile(
                                        item: item,
                                        isFavorite: store.isFavorite(recipeID: item.id),
                                        onSelect: {
                                            AppHaptics.lightTap()
                                            store.recordRecipeViewed(id: item.id)
                                            selectedItem = item
                                        },
                                        onToggleFavorite: {
                                            let added = store.toggleFavorite(recipeID: item.id)
                                            if added {
                                                AppHaptics.successNotice()
                                                SystemSounds.play(SystemSounds.favoriteAdded)
                                                SystemSounds.play(SystemSounds.successPing)
                                            }
                                        },
                                        onDeleteUserRecipe: item.isUserOwned
                                            ? { id in
                                                store.deleteUserRecipe(id: id)
                                                if selectedItem?.id == id {
                                                    selectedItem = nil
                                                }
                                            }
                                            : nil
                                    )
                                    .id(item.tileRefreshToken)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 78)
                    .padding(.top, 6)
                }
                .scrollContentBackground(.hidden)

                RecipeLibraryFAB {
                    AppHaptics.lightTap()
                    recipeEditorPresentation = .create(draftRecipeID: UserRecipeRecord.newDraftID())
                }
                .zIndex(10)
                .padding(.trailing, 20)
                .padding(.bottom, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedItem) { item in
            RecipeDetailView(item: item)
                .environmentObject(store)
                .presentationDetents([.large])
                .sheetPresentationChrome()
        }
        .sheet(item: $recipeEditorPresentation) { presentation in
            RecipeEditorView(presentation: presentation)
                .environmentObject(store)
        }
        .onAppear {
            viewModel.searchText = store.lastSearchedKeyword
            store.evaluateAchievements()
        }
        .onChange(of: viewModel.searchText) { newValue in
            store.updateSearchKeyword(newValue)
        }
        .scrollIndicators(.hidden, axes: .vertical)
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                CookingLogoBadge()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 10) {
                    TextField(
                        "",
                        text: $viewModel.searchText,
                        prompt: Text("Search recipes or ingredients")
                            .foregroundStyle(Color.appTextSecondary)
                    )
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .appElevatedCard(cornerRadius: 16, tier: .subtle)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var recipeTagChipsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Kitchen filters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Button {
                    AppHaptics.lightTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeRecipeTagFilters.removeAll()
                    }
                } label: {
                    Text("Clear")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(activeRecipeTagFilters.isEmpty ? Color.appTextSecondary.opacity(0.45) : Color.appAccent)
                }
                .disabled(activeRecipeTagFilters.isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RecipeTag.allCases) { tag in
                        let selected = activeRecipeTagFilters.contains(tag)
                        Button {
                            AppHaptics.lightTap()
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                                if selected {
                                    activeRecipeTagFilters.remove(tag)
                                } else {
                                    activeRecipeTagFilters.insert(tag)
                                }
                            }
                        } label: {
                            Text(tag.filterLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selected ? Color.appBackground : Color.appTextSecondary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 10)
                                .background(chipBackdrop(selected: selected))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text(activeRecipeTagFilters.isEmpty ? "Every recipe stays visible." : "Showing recipes matching all selected badges.")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 12) {
            ForEach(RecipeExplorerFilterMode.allCases) { mode in
                Button {
                    AppHaptics.lightTap()
                    withAnimation(.easeInOut(duration: 0.24)) {
                        viewModel.filterMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.filterMode == mode ? Color.appBackground : Color.appTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(modePickerBackdrop(isSelected: viewModel.filterMode == mode))
                        .minimumScaleFactor(0.74)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
            Spacer(minLength: 0)
        }
    }

    private func modePickerBackdrop(isSelected: Bool) -> some View {
        ZStack {
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppVisualGradients.primaryButton)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppVisualGradients.mutedChipFill)
                }
            }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSelected
                        ? LinearGradient(colors: [.white.opacity(0.28), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.appPrimary.opacity(0.18), Color.appAccent.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(isSelected ? 0.4 : 0.22), radius: isSelected ? 14 : 8, x: 0, y: isSelected ? 10 : 5)
        .shadow(color: Color.appAccent.opacity(isSelected ? 0.26 : 0), radius: isSelected ? 12 : 0, x: 0, y: 6)
    }

    private func chipBackdrop(selected: Bool) -> some View {
        ZStack {
            Group {
                if selected {
                    Capsule()
                        .fill(AppVisualGradients.primaryButton)
                } else {
                    Capsule()
                        .fill(AppVisualGradients.mutedChipFill)
                }
            }

            Capsule()
                .stroke(
                    selected
                        ? LinearGradient(colors: [.white.opacity(0.35), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.appPrimary.opacity(0.16), Color.appAccent.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(selected ? 0.36 : 0.18), radius: selected ? 10 : 5, x: 0, y: selected ? 6 : 4)
        .shadow(color: Color.appAccent.opacity(selected ? 0.22 : 0), radius: selected ? 8 : 0, x: 0, y: 4)
    }
}

private struct GuidedBrowseHint: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 38))
                .foregroundStyle(Color.appPrimary)
            Text("Favorite recipes surface here instantly—browse to find your staples.")
                .foregroundStyle(Color.appTextSecondary)
                .font(.footnote.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .appElevatedCard(cornerRadius: 18, tier: .subtle)
        .transition(.opacity)
    }
}

private struct EmptyFavoritesRecipesView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary.opacity(0.92))
                .symbolRenderingMode(.hierarchical)

            UtensilsIllustration()
                .frame(height: 140)

            Text("No favourites yet. Discover new meals!")
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextSecondary)
                .padding(.horizontal, 12)

            Text("Search for ingredients or tap the heart icon to curate staples you love.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .appElevatedCard(cornerRadius: 20, tier: .standard)
    }
}

private struct EmptySearchRecipesView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundStyle(Color.appAccent.opacity(0.85))
            Text("No recipes matched that search.")
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline.weight(.semibold))
            Text("Try a shorter ingredient or switch filters.")
                .foregroundStyle(Color.appTextSecondary.opacity(0.82))
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appElevatedCard(cornerRadius: 20, tier: .standard)
    }
}

private struct UtensilsIllustration: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appPrimary.opacity(0.18), lineWidth: 2)
                .frame(width: 150, height: 150)

            Image(systemName: "flame.fill")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .rotationEffect(.degrees(-18))
                .offset(x: -18)

            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 66, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
                .rotationEffect(.degrees(10))
                .offset(x: 24, y: 14)

            Capsule(style: .continuous)
                .fill(Color.appAccent.opacity(0.48))
                .frame(width: 90, height: 10)
                .offset(y: -42)
                .blur(radius: 1)
        }
        .scaleEffect(appeared ? 1 : 0.78)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}
