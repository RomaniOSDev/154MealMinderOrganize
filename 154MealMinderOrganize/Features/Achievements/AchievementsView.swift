import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: MealPlannerStore

    @State private var contentVisible = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var metrics: AchievementMetrics {
        store.achievementMetrics
    }

    private var unlockedCount: Int {
        AchievementDefinition.all.filter { $0.isUnlocked(metrics) }.count
    }

    private let totalBadges = AchievementDefinition.all.count

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    milestonesIntro
                    lifetimeGlanceStrip
                    overviewRingCard
                    momentumCard
                    badgesSectionHeader
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(AchievementDefinition.all.enumerated()), id: \.element.id) { index, achievement in
                            let unlocked = achievement.isUnlocked(metrics)
                            AchievementBadgeTile(
                                definition: achievement,
                                unlocked: unlocked,
                                index: index,
                                visible: contentVisible
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 52)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.evaluateAchievements()
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                contentVisible = true
            }
        }
    }

    private var milestonesIntro: some View {
        HStack(alignment: .top, spacing: 16) {
            MilestonesMedalArtwork()
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text("Milestones")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Celebrate progress as you cook, plan, and shop. Every badge reflects real activity in the app.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 20, tier: .standard)
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0), value: contentVisible)
    }

    /// Compact at-a-glance counts (also detailed in Activity pulse below).
    private var lifetimeGlanceStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                glanceStatChip(
                    icon: "doc.text.viewfinder",
                    caption: "Recipes viewed",
                    value: store.recipesViewed
                )
                glanceStatChip(
                    icon: "cart.fill",
                    caption: "Grocery rounds",
                    value: store.listsCompleted
                )
                glanceStatChip(
                    icon: "flame.fill",
                    caption: "Day streak",
                    value: store.streakDays
                )
            }
        }
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 10)
        .animation(.spring(response: 0.48, dampingFraction: 0.82).delay(0.03), value: contentVisible)
    }

    private func glanceStatChip(icon: String, caption: String, value: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.appPrimary.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                Text(caption)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(width: 168, alignment: .leading)
        .appElevatedCard(cornerRadius: 18, tier: .subtle)
    }

    private var overviewRingCard: some View {
        let progress = Double(unlockedCount) / Double(max(1, totalBadges))

        return HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.appSurface, lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: contentVisible ? progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appPrimary)
                    Text("of \(totalBadges)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Badge progress")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Unlock all eight by exploring recipes, favourites, grocery runs, and streaks.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appBackground.opacity(0.8))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(0.9), Color.appPrimary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (contentVisible ? progress : 0))
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .appElevatedCard(cornerRadius: 22, tier: .standard)
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: contentVisible)
        .animation(.easeOut(duration: 0.85).delay(0.12), value: contentVisible)
    }

    private var momentumCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Text("Activity pulse")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 0)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                metricCell(
                    icon: "doc.text.viewfinder",
                    title: "Recipes viewed",
                    value: store.recipesViewed,
                    target: 50
                )
                metricCell(
                    icon: "heart.fill",
                    title: "Favourite adds",
                    value: store.favouritesAddedTotal,
                    target: 8
                )
                metricCell(
                    icon: "cart.fill",
                    title: "Grocery rounds",
                    value: store.listsCompleted,
                    target: 12
                )
                metricCell(
                    icon: "flame.fill",
                    title: "Day streak",
                    value: store.streakDays,
                    target: 7
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 22, tier: .standard)
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 18)
        .animation(.spring(response: 0.52, dampingFraction: 0.8).delay(0.1), value: contentVisible)
    }

    private var badgesSectionHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.grid.2x2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text("Badge collection")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.appTextPrimary)
                .tracking(0.6)
            Spacer()
            Text("\(totalBadges)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.appPrimary.opacity(0.85)))
        }
        .padding(.top, 4)
        .opacity(contentVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.14), value: contentVisible)
    }

    private func metricCell(icon: String, title: String, value: Int, target: Int) -> some View {
        let progress = min(Double(value) / Double(max(1, target)), 1)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.appPrimary.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.appTextSecondary)
                    .tracking(0.5)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("/ \(target)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }

                ProgressView(value: progress)
                    .tint(Color.appAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .appInsetWell(cornerRadius: 18)
    }
}

// MARK: - Medal artwork (SwiftUI only)

private struct MilestonesMedalArtwork: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.45), Color.appSurface.opacity(0.2)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 40
                    )
                )
                .scaleEffect(glow ? 1.05 : 0.94)
                .opacity(0.9)

            Image(systemName: "rosette")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Badge tile

private struct AchievementBadgeTile: View {
    let definition: AchievementDefinition
    let unlocked: Bool
    let index: Int
    let visible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(format: "%02d", index + 1))
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.appTextSecondary.opacity(0.75))
                Spacer()
                Image(systemName: unlocked ? "sparkles" : "lock.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.6))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: unlocked
                                ? [Color.appPrimary.opacity(0.22), Color.appAccent.opacity(0.12)]
                                : [Color.appSurface.opacity(0.9), Color.appBackground.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if unlocked {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            AngularGradient(
                                colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                }

                Image(systemName: unlocked ? "star.fill" : "hourglass")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(
                        unlocked
                            ? LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.appTextSecondary.opacity(0.65), Color.appTextSecondary.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(color: unlocked ? Color.appPrimary.opacity(0.35) : .clear, radius: 12, y: 4)
            }
            .frame(height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(definition.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(definition.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            HStack(spacing: 6) {
                Image(systemName: unlocked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.5))
                    .font(.caption.weight(.semibold))
                Text(unlocked ? "Unlocked" : "Keep going")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(unlocked ? Color.appPrimary.opacity(0.14) : Color.appBackground.opacity(0.5))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSurface.opacity(unlocked ? 0.95 : 0.78))
                .shadow(color: Color.black.opacity(unlocked ? 0.18 : 0.08), radius: unlocked ? 10 : 6, y: unlocked ? 6 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appPrimary.opacity(unlocked ? 0.22 : 0.08), lineWidth: unlocked ? 1.2 : 1)
        )
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.88)
        .offset(y: visible ? 0 : 20)
        .animation(
            .spring(response: 0.46, dampingFraction: 0.78)
                .delay(0.12 + Double(index) * 0.045),
            value: visible
        )
    }
}
