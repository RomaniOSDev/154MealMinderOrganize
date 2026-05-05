import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @State private var showResetAlert = false

    private var versionLabel: String {
        let bundleValue = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let text = bundleValue as? String
        return text ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    statsCard

                    VStack(spacing: 0) {
                        settingsRow(icon: "star.circle.fill", title: "Rate us") {
                            AppHaptics.lightTap()
                            rateApp()
                        }

                        Divider()
                            .overlay(Color.appTextSecondary.opacity(0.35))

                        settingsRow(icon: "hand.raised.fill", title: "Privacy Policy") {
                            openExternalURL(.privacyPolicy)
                        }

                        Divider()
                            .overlay(Color.appTextSecondary.opacity(0.35))

                        settingsRow(icon: "doc.plaintext.fill", title: "Terms") {
                            openExternalURL(.termsOfUse)
                        }

                        Divider()
                            .overlay(Color.appTextSecondary.opacity(0.35))

                        settingsRow(icon: "envelope.open.fill", title: "Support") {
                            AppHaptics.lightTap()
                            openMail()
                        }

                        Divider()
                            .overlay(Color.appTextSecondary.opacity(0.35))

                        Button {
                            AppHaptics.lightTap()
                            showResetAlert = true
                        } label: {
                            Label("Reset All Data", systemImage: "trash.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.red.opacity(0.88))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                        .alert("Erase everything?", isPresented: $showResetAlert) {
                            Button("Cancel", role: .cancel) {
                                AppHaptics.lightTap()
                            }
                            Button("Reset", role: .destructive) {
                                AppHaptics.mediumImpact()
                                store.resetAllData()
                                store.evaluateAchievements()
                            }
                        } message: {
                            Text("This clears recipes progress, groceries, timers, and achievements counters from this device.")
                        }
                    }
                    .padding(.vertical, 6)
                    .appElevatedCard(cornerRadius: 22, tier: .standard)

                    Text("Version \(versionLabel)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 64)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.evaluateAchievements()
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Weekly Snapshot")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            VStack(alignment: .leading, spacing: 12) {
                statLine(title: "Meaningful sessions completed", detail: "\(store.totalSessionsCompleted)")
                statLine(title: "Active minutes accounted", detail: "\(store.totalMinutesUsed)")
                statLine(title: "Current cooking streak", detail: "\(store.streakDays) days")
                statLine(title: "Saved grocery lines", detail: "\(store.groceryItems.count) active rows")
                statLine(title: "Bookmarks stored", detail: "\(store.favoriteRecipeIDs.count)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 22, tier: .standard)
    }

    private func statLine(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .foregroundStyle(Color.appPrimary)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.74)
                .lineLimit(1)
        }
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 42, alignment: .center)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.7))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .buttonStyle(SettingsRowButtonStyle())
        .accessibilityHint("Opens \(title)")
    }

    private func openMail() {
        guard let url = URL(string: "mailto:support@example.com") else {
            return
        }
        UIApplication.shared.open(url)
    }

    private func openExternalURL(_ link: AppExternalLink) {
        AppHaptics.lightTap()
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
