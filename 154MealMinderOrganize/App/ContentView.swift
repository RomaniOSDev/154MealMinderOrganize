import SwiftUI

struct ContentView: View {
    @StateObject private var store = MealPlannerStore()
    @StateObject private var achievementPresenter = AchievementBannerPresenter()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainShellView(bannerPresenter: achievementPresenter)
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            UIKitTableChromeBootstrap.applyOnce()
        }
    }
}

#Preview {
    ContentView()
}
