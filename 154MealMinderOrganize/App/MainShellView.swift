import SwiftUI

enum MainShellDestination: CaseIterable {
    case home
    case recipes
    case toolkit
    case milestones
    case settings

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .recipes: return "square.grid.2x2.fill"
        case .toolkit: return "basket.fill"
        case .milestones: return "star.square.on.square.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .recipes: return "Recipes"
        case .toolkit: return "Prep"
        case .milestones: return "Milestones"
        case .settings: return "Settings"
        }
    }
}

struct MainShellView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @ObservedObject var bannerPresenter: AchievementBannerPresenter

    @State private var tab: MainShellDestination = .home

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch tab {
                case .home:
                    HomeView(shellTab: $tab)
                case .recipes:
                    RecipeExplorerView()
                case .toolkit:
                    MealToolsHubView()
                case .milestones:
                    AchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .animation(.easeInOut(duration: 0.26), value: tab)

            AchievementBannerOverlay(presenter: bannerPresenter)
                .padding(.top, 8)
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabRail(selection: $tab)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 6)
        }
        .screenBackground()
    }
}

private struct CustomTabRail: View {
    @Binding var selection: MainShellDestination

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MainShellDestination.allCases, id: \.self) { item in
                Button {
                    AppHaptics.lightTap()
                    guard selection != item else { return }
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        selection = item
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20, weight: .semibold))

                        Text(item.label)
                            .font(.caption2.weight(.semibold))
                            .minimumScaleFactor(0.74)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == item ? Color.appBackground : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 10)
                    .background(tabSelectionBackdrop(isSelected: selection == item))
                }
                .buttonStyle(TabSquishButtonStyle())
                .accessibilityHint("Opens \(item.label.lowercased()) tab.")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppVisualGradients.segmentedTrack)
                    .overlay(AppVisualGradients.specularRim(cornerRadius: 22))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppVisualGradients.cardBorder.opacity(0.88), lineWidth: 1.1)
            }
            .shadow(color: Color.black.opacity(0.48), radius: 24, x: 0, y: 18)
            .shadow(color: Color.appAccent.opacity(0.14), radius: 14, x: 0, y: 10)
        )
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
        .allowsHitTesting(true)
        .animation(.easeInOut(duration: 0.22), value: selection)
    }

    private func tabSelectionBackdrop(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppVisualGradients.primaryButton)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.42), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.36), radius: 12, x: 0, y: 7)
                    .shadow(color: Color.appAccent.opacity(0.28), radius: 12, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppVisualGradients.mutedChipFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.appPrimary.opacity(0.14), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.85
                            )
                    )
            }
        }
    }
}

private struct TabSquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.42, dampingFraction: 0.73), value: configuration.isPressed)
            .brightness(configuration.isPressed ? 0.04 : 0)
    }
}
