import Combine
import Foundation
import SwiftUI

@MainActor
final class AchievementBannerPresenter: ObservableObject {
    @Published private(set) var bannerTitle: String?

    private var queue: [String] = []
    private var isShowing = false
    private var cancellables = Set<AnyCancellable>()
    private var dismissWorkItem: DispatchWorkItem?

    init() {
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .compactMap { notification in
                notification.userInfo?["title"] as? String
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                self?.enqueue(title)
            }
            .store(in: &cancellables)
    }

    func enqueue(_ title: String) {
        queue.append(title)
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard !isShowing else { return }
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        isShowing = true
        dismissWorkItem?.cancel()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.76)) {
            bannerTitle = next
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.28)) {
                self.bannerTitle = nil
            }
            self.isShowing = false
            self.presentNextIfNeeded()
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}

struct AchievementBannerOverlay: View {
    @ObservedObject var presenter: AchievementBannerPresenter

    var body: some View {
        VStack {
            if let title = presenter.bannerTitle {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                    Text("Unlocked: \(title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.appSurface.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.28), radius: 16, y: 8)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }
}
