import SwiftUI
import UIKit

/// Dashboard with glanceable widgets: plan, groceries, timers, recents, and milestones.
struct HomeView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @Binding var shellTab: MainShellDestination

    @State private var pickedRecipe: RecipeListItem?

    private var groceriesTotal: Int { store.groceryItems.count }
    private var groceriesPending: Int {
        store.groceryItems.filter { !$0.completed }.count
    }

    private var metrics: AchievementMetrics { store.achievementMetrics }
    private var unlockedBadges: Int {
        AchievementDefinition.all.filter { $0.isUnlocked(metrics) }.count
    }

    private var todayPlannerDay: WeekPlannerDay { WeekPlannerDay.today() }
    private var todayPlannedRecipeID: String? {
        store.weeklyMealRecipeID(for: todayPlannerDay).flatMap { $0.isEmpty ? nil : $0 }
    }

    private var recentItems: [RecipeListItem] {
        store.recentlyViewedRecipeIDs
            .prefix(14)
            .compactMap { RecipeResolution.listItem(recipeID: $0, store: store) }
    }

    private var favoriteItems: [RecipeListItem] {
        store.favoriteRecipeIDs
            .prefix(10)
            .compactMap { RecipeResolution.listItem(recipeID: $0, store: store) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heroHeader
                    shortcutsRow
                    timersWidget
                    weeklyPlanCard
                    groceryProgressCard

                    if !recentItems.isEmpty {
                        horizontalRecipeSection(
                            title: "Pick up where you left off",
                            subtitle: "Recently opened recipes",
                            items: Array(recentItems)
                        )
                    }

                    if !favoriteItems.isEmpty {
                        horizontalRecipeSection(
                            title: "Favorites",
                            subtitle: "One tap away",
                            items: Array(favoriteItems)
                        )
                    }

                    milestonesWidget
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 92)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $pickedRecipe) { item in
            RecipeDetailView(item: item)
                .environmentObject(store)
                .presentationDetents([.large])
                .sheetPresentationChrome()
        }
        .onAppear {
            store.evaluateAchievements()
        }
    }

    // MARK: - Hero

    private var heroHeader: some View {
        ZStack(alignment: .leading) {
            Circle()
                .fill(Color.appAccent.opacity(0.22))
                .frame(width: 140, height: 140)
                .blur(radius: 36)
                .offset(x: -48, y: -28)

            Circle()
                .fill(Color.appPrimary.opacity(0.18))
                .frame(width: 110, height: 110)
                .blur(radius: 28)
                .offset(x: 8, y: 12)

            VStack(alignment: .leading, spacing: 12) {
                Text(greetingLine)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Color.appTextPrimary)

                Text(
                    Date.now,
                    format: .dateTime
                        .weekday(.wide)
                        .month(.abbreviated)
                        .day()
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)

                FlowStatsRow(
                    streak: store.streakDays,
                    grocerOpen: groceriesPending,
                    timers: store.cookingTimers.count,
                    badges: unlockedBadges,
                    badgesTotal: AchievementDefinition.all.count
                )
                .padding(.top, 4)
            }
            .padding(.trailing, 76)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.appPrimary.opacity(0.14))
                    .frame(width: 92, height: 92)
                    .blur(radius: 26)
                    .offset(x: 24, y: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Shortcuts

    private var shortcutsRow: some View {
        HStack(spacing: 10) {
            HomeShortcutChip(
                title: "Recipes",
                icon: "square.grid.2x2.fill",
                tint: Color.appPrimary
            ) {
                shellTab = .recipes
            }
            HomeShortcutChip(
                title: "Prep",
                icon: "basket.fill",
                tint: Color.appAccent
            ) {
                shellTab = .toolkit
            }
            HomeShortcutChip(
                title: "Milestones",
                icon: "star.square.on.square.fill",
                tint: Color.appPrimary.opacity(0.92)
            ) {
                shellTab = .milestones
            }
        }
    }

    // MARK: - Timers

    @ViewBuilder
    private var timersWidget: some View {
        if store.cookingTimers.isEmpty {
            EmptyView()
        } else {
            let timerPreviewList = Array(store.cookingTimers.prefix(4))

            HomeWidgetChrome(
                title: "Cooking timers",
                systemImage: "timer",
                onTapHeader: { shellTab = .toolkit },
                trailingLabel: {
                    Text("\(store.cookingTimers.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.appAccent.opacity(0.88)))
                },
                content: {
                    TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                        VStack(spacing: 0) {
                            ForEach(Array(timerPreviewList.enumerated()), id: \.element.id) { index, timer in
                                let remain = timer.remainingSeconds(at: timeline.date)
                                HStack(spacing: 14) {
                                    Image(systemName: timer.isPaused ? "pause.circle.fill" : "flame.circle.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(
                                            timer.isPaused ? Color.appTextSecondary : Color.appAccent
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(timer.dishName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.appTextPrimary)
                                            .lineLimit(1)

                                        if let cap = timerLinkCaption(for: timer) {
                                            Text(cap)
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(Color.appTextSecondary.opacity(0.92))
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer(minLength: 0)

                                    Text(formatCountdown(remain))
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.appTextPrimary.opacity(remain == 0 ? 0.45 : 1))
                                }
                                .padding(.vertical, 10)

                                if index < timerPreviewList.count - 1 {
                                    Divider()
                                        .background(Color.appPrimary.opacity(0.08))
                                }
                            }
                        }
                    }
                }
            )
        }
    }

    private func timerLinkCaption(for timer: PersistedCookingTimer) -> String? {
        guard let rid = timer.linkedRecipeID else { return nil }
        let title = RecipeResolution.title(recipeID: rid, store: store)
        if let step = timer.linkedStepIndex {
            return "\(title) • Step \(step + 1)"
        }
        return title
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    // MARK: - Weekly snippet

    private var weeklyPlanCard: some View {
        HomeWidgetChrome(
            title: "Today • \(todayPlannerDay.shortTitle)",
            systemImage: "calendar",
            onTapHeader: { shellTab = .toolkit },
            trailingLabel: { EmptyView() },
            content: {
            if let pid = todayPlannedRecipeID,
               let recipe = RecipeResolution.listItem(recipeID: pid, store: store)
            {
                Button {
                    AppHaptics.lightTap()
                    openRecipe(recipe.id)
                } label: {
                    HStack(spacing: 14) {
                        HomeRecipeThumbnailDot(item: recipe)
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Planned dish")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(Color.appAccent)
                                .textCase(.uppercase)
                                .tracking(0.4)

                            Text(recipe.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .minimumScaleFactor(0.88)

                            Text(recipe.summary.isEmpty ? "Open steps and ingredients." : recipe.summary)
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2.weight(.semibold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appAccent, Color.appSurface.opacity(0.35))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                Divider().background(Color.appPrimary.opacity(0.08))

                Button {
                    AppHaptics.lightTap()
                    shellTab = .toolkit
                } label: {
                    Label("Edit weekly plan in Prep", systemImage: "calendar.badge.clock")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No recipe pinned yet for \(todayPlannerDay.shortTitle).")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        AppHaptics.lightTap()
                        shellTab = .toolkit
                    } label: {
                        Label("Open weekly planner", systemImage: "plus.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
            }
        )
    }

    // MARK: - Grocery

    private var groceryProgressCard: some View {
        let total = groceriesTotal
        let pending = groceriesPending

        return HomeWidgetChrome(
            title: "Grocery list",
            systemImage: "cart.fill",
            onTapHeader: { shellTab = .toolkit },
            trailingLabel: { EmptyView() },
            content: {
            if total == 0 {
                Text("Your list is empty. Add staples from Prep or a recipe’s ingredient sheet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                let done = total - pending
                let progress = Double(done) / Double(max(1, total))

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("\(pending) left • \(done) gathered")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.appAccent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appBackground.opacity(0.55))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent.opacity(0.95), Color.appPrimary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 9)
                    .clipShape(Capsule())

                    let sample = store.groceryItems.filter { !$0.completed }.prefix(4).map(\.name)
                    if !sample.isEmpty {
                        Text(sample.joined(separator: " · "))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appTextPrimary.opacity(0.85))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider().background(Color.appPrimary.opacity(0.06))

            Button {
                AppHaptics.lightTap()
                shellTab = .toolkit
            } label: {
                Label("Open list in Prep", systemImage: "arrow.right.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
            .padding(.top, total == 0 ? 10 : 2)
            }
        )
    }

    // MARK: - Recipe strips

    private func horizontalRecipeSection(title: String, subtitle: String, items: [RecipeListItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                Button {
                    AppHaptics.lightTap()
                    shellTab = .recipes
                } label: {
                    Text("See all")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            AppHaptics.lightTap()
                            openRecipe(item.id)
                        } label: {
                            HomeWideRecipeTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Milestones

    private var milestonesWidget: some View {
        HomeWidgetChrome(
            title: "Milestones",
            systemImage: "rosette",
            onTapHeader: { shellTab = .milestones },
            trailingLabel: { EmptyView() },
            content: {
            let ratio = Double(unlockedBadges) / Double(max(1, AchievementDefinition.all.count))

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.appSurface, lineWidth: 8)
                        .frame(width: 74, height: 74)

                    Circle()
                        .trim(from: 0, to: ratio)
                        .stroke(
                            AngularGradient(
                                colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 74, height: 74)
                        .rotationEffect(.degrees(-90))

                    Text("\(unlockedBadges)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.appPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(unlockedBadges) of \(AchievementDefinition.all.count) badges unlocked.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        unlockedBadges >= AchievementDefinition.all.count
                            ? "You crushed every milestone—keep exploring new recipes!"
                            : "Cook, favourite, shop, and show up daily to reveal the rest."
                    )
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)

                    ProgressView(value: ratio)
                        .tint(Color.appAccent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)

            Divider().background(Color.appPrimary.opacity(0.06))

            Button {
                AppHaptics.lightTap()
                shellTab = .milestones
            } label: {
                Label("View full milestones", systemImage: "sparkles.rectangle.stack.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            }
        )
    }

    private func openRecipe(_ id: String) {
        guard let item = RecipeResolution.listItem(recipeID: id, store: store) else { return }
        store.recordRecipeViewed(id: id)
        pickedRecipe = item
    }
}

// MARK: - Small components

private struct FlowStatsRow: View {
    let streak: Int
    let grocerOpen: Int
    let timers: Int
    let badges: Int
    let badgesTotal: Int

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            HomeNanoStat(icon: "flame.fill", caption: "Streak", value: "\(streak)d", hue: Color.appAccent)
            HomeNanoStat(icon: "cart", caption: "Grocer open", value: "\(grocerOpen)", hue: Color.appPrimary)
            HomeNanoStat(icon: "timer", caption: "Timers", value: "\(timers)", hue: Color.appAccent.opacity(0.95))
            HomeNanoStat(icon: "rosette", caption: "Badges", value: "\(badges)/\(badgesTotal)", hue: Color.appPrimary)
        }
    }
}

private struct HomeNanoStat: View {
    let icon: String
    let caption: String
    let value: String
    let hue: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(hue.opacity(0.95))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(hue.opacity(0.14)))

            VStack(alignment: .leading, spacing: 3) {
                Text(caption.uppercased())
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.92))
                    .tracking(0.35)

                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.appTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .appElevatedCard(cornerRadius: 16, tier: .subtle)
    }
}

private struct HomeShortcutChip: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            AppHaptics.lightTap()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.95))
                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .appElevatedCard(cornerRadius: 18, tier: .subtle)
        }
        .buttonStyle(HomeSquishPressStyle())
    }
}

private struct HomeSquishPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.74), value: configuration.isPressed)
            .brightness(configuration.isPressed ? 0.05 : 0)
    }
}

private struct HomeWidgetChrome<
    Trailing: View,
    Content: View
>: View {
    let title: String
    let systemImage: String
    let onTapHeader: () -> Void
    @ViewBuilder let trailingLabel: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        systemImage: String,
        onTapHeader: @escaping () -> Void,
        @ViewBuilder trailingLabel: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.onTapHeader = onTapHeader
        self.trailingLabel = trailingLabel
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                AppHaptics.lightTap()
                onTapHeader()
            } label: {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    Spacer()

                    trailingLabel()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.body.weight(.semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.appTextSecondary.opacity(0.72), Color.appSurface.opacity(0.4))
                }
            }
            .buttonStyle(.plain)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 24, tier: .prominent)
    }
}

private struct HomeWideRecipeTile: View {
    let item: RecipeListItem

    @EnvironmentObject private var store: MealPlannerStore
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appPrimary.opacity(0.12))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: HomeStripMetrics.tileWidth, height: HomeStripMetrics.imageHeight)
                        .clipped()
                } else {
                    Image(systemName: item.previewSymbolName)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.appTextPrimary.opacity(0.88), Color.appPrimary.opacity(0.75))
                        .font(.system(size: 30, weight: .semibold))
                }
            }
            .frame(width: HomeStripMetrics.tileWidth, height: HomeStripMetrics.imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.84)
                .frame(width: HomeStripMetrics.tileWidth, alignment: .leading)

            Text(item.summary.isEmpty ? " " : item.summary)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary.opacity(item.summary.isEmpty ? 0.25 : 0.95))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(width: HomeStripMetrics.tileWidth, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(width: HomeStripMetrics.tileWidth + 22, alignment: .topLeading)
        .appElevatedCard(cornerRadius: 20, tier: .subtle)
        .onAppear { refreshThumbnail() }
        .onChange(of: item.tileRefreshToken) { _, _ in refreshThumbnail() }
        .onChange(of: store.userRecipes) { _, _ in refreshThumbnail() }
    }

    private func refreshThumbnail() {
        guard let user = item.userRecord(), user.hasCoverImage else {
            thumbnail = nil
            return
        }
        thumbnail = UserRecipeImageStore.load(recipeID: user.id)
    }
}

private enum HomeStripMetrics {
    static let tileWidth: CGFloat = 154
    static let imageHeight: CGFloat = 100
}

/// Square thumbnail for planner row.
private struct HomeRecipeThumbnailDot: View {
    let item: RecipeListItem

    @EnvironmentObject private var store: MealPlannerStore
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appPrimary.opacity(0.14))

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
            } else {
                Image(systemName: item.previewSymbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.appAccent, Color.appPrimary.opacity(0.55))
                    .symbolRenderingMode(.palette)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appPrimary.opacity(0.12), lineWidth: 1)
        )
        .onAppear { refreshThumbnail() }
        .onChange(of: item.tileRefreshToken) { _, _ in refreshThumbnail() }
        .onChange(of: store.userRecipes) { _, _ in refreshThumbnail() }
    }

    private func refreshThumbnail() {
        guard let user = item.userRecord(), user.hasCoverImage else {
            thumbnail = nil
            return
        }
        thumbnail = UserRecipeImageStore.load(recipeID: user.id)
    }
}

#Preview {
    HomeView(shellTab: .constant(.home))
        .environmentObject(MealPlannerStore())
}
