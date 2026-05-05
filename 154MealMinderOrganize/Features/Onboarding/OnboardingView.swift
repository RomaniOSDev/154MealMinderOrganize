import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: MealPlannerStore

    @State private var pageIndex = 0
    @State private var curtain = false

    private let subtitles = [
        "Plans, groceries, and timers stay on your device—with a glanceable Home and a Prep toolkit for lists and timers.",
        "Browse the curated library, save favourites with a tap, scale ingredients when portions change—it’s built for nightly cooking.",
        "You’re moments away from pinning a weekday meal, syncing your cart, and starting cook-mode walkthroughs."
    ]

    private let titles = [
        "Kitchen command centre",
        "Recipes worth revisiting",
        "Your table is waiting"
    ]

    private let pageGlyphs: [(title: String, detail: String, glyph: OnboardingGlyph)] = [
        ("Home & Prep", "Tap into weekly planning • Groceries • Cooking timers.", .plannerStack),
        ("Recipes tab", "Filter by tags • Favourite • Detail sheets with cook mode.", .bookHeart),
        ("Privacy-first", "Nothing leaves this phone unless you export or share manually.", .sparkTrail)
    ]

    private var accentTitleGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appTextPrimary, Color.appPrimary.opacity(0.92)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                onboardingHeader
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 14)

                TabView(selection: $pageIndex) {
                    onboardingSlide(glyph: .plannerStack)
                        .tag(0)
                    onboardingSlide(glyph: .bookHeart)
                        .tag(1)
                    onboardingSlide(glyph: .sparkTrail)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.32), value: pageIndex)

                bottomPanel
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
            .opacity(curtain ? 1 : 0)
            .offset(y: curtain ? 0 : 28)
            .onAppear {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                    curtain = true
                }
            }
        }
        .screenBackground()
    }

    private var onboardingHeader: some View {
        HStack(spacing: 14) {
            onboardingBrandOrb
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text("Meal Minder")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(accentTitleGradient)
                Text("Organize meals locally—beautifully.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 14)
        .appElevatedCard(cornerRadius: 22, tier: .subtle)
    }

    private var onboardingBrandOrb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AppVisualGradients.primaryButton)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.32), radius: 10, x: 0, y: 6)
                .shadow(color: Color.appAccent.opacity(0.2), radius: 8, x: 0, y: 4)

            Image(systemName: "fork.knife")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
    }

    private func onboardingSlide(glyph: OnboardingGlyph) -> some View {
        OnboardingGlyphPanel(glyph: glyph)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingPagerDots

            Text(titles[pageIndex])
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(accentTitleGradient)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.leading)

            Text(subtitles[pageIndex])
                .font(.body.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.25), value: pageIndex)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: pageGlyphs[pageIndex].glyph.miniIconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.appAccent.opacity(0.12)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pageGlyphs[pageIndex].title)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.appPrimary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text(pageGlyphs[pageIndex].detail)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: advance) {
                Text(pageIndex == titles.count - 1 ? "Start cooking at home" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.74)
                    .lineLimit(1)
            }
            .buttonStyle(AppPrimaryRoundedButtonStyle())

            if pageIndex < titles.count - 1 {
                Button {
                    AppHaptics.lightTap()
                    store.markOnboardingFinished()
                } label: {
                    Text("Jump to the app")
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(Color.appAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }

            Text(pageIndex >= titles.count - 1 ? "Your data stays on-device—welcome aboard." : "Swipe the collage or tap Continue to keep going.")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary.opacity(0.78))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
                .accessibilityHidden(true)
        }
        .padding(22)
        .appElevatedCard(cornerRadius: 28, tier: .prominent)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: pageIndex)
    }

    private var onboardingPagerDots: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< titles.count, id: \.self) { index in
                let active = index == pageIndex
                Group {
                    if active {
                        Capsule(style: .continuous)
                            .fill(AppVisualGradients.primaryButton)
                    } else {
                        Capsule(style: .continuous)
                            .fill(AppVisualGradients.mutedChipFill)
                    }
                }
                .frame(width: active ? 32 : 9, height: 9)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(active ? 0.28 : 0), lineWidth: 1)
                    )
                    .shadow(color: active ? Color.black.opacity(0.32) : Color.clear, radius: 10, x: 0, y: 6)
                    .shadow(color: active ? Color.appAccent.opacity(0.22) : Color.clear, radius: 10, x: 0, y: 4)
                    .animation(.spring(response: 0.48, dampingFraction: 0.76), value: pageIndex)
            }
        }
        .padding(.horizontal, 2)
    }

    private func advance() {
        AppHaptics.lightTap()
        if pageIndex == titles.count - 1 {
            AppHaptics.mediumImpact()
            SystemSounds.play(SystemSounds.successPing)
            AppHaptics.successNotice()
            store.markOnboardingFinished()
        } else {
            SystemSounds.play(SystemSounds.interfaceTick)
            withAnimation(.easeInOut(duration: 0.32)) {
                pageIndex += 1
            }
        }
    }
}

private enum OnboardingGlyph {
    case plannerStack
    case bookHeart
    case sparkTrail

    var miniIconName: String {
        switch self {
        case .plannerStack: return "calendar.circle.fill"
        case .bookHeart: return "book.pages.fill"
        case .sparkTrail: return "lock.shield.fill"
        }
    }
}

private struct OnboardingGlyphPanel: View {
    let glyph: OnboardingGlyph
    @State private var sprung = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppVisualGradients.elevatedCardFill)
                .overlay(AppVisualGradients.specularRim(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppVisualGradients.cardBorder, lineWidth: 1.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appPrimary.opacity(0.045),
                                    Color.appAccent.opacity(0.038),
                                    Color.clear
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                )

            glowAura

            Group {
                switch glyph {
                case .plannerStack:
                    PlannerArtwork()
                case .bookHeart:
                    BookHeartArtwork()
                case .sparkTrail:
                    SparkTrailArtwork()
                }
            }
            .padding(36)
            .scaleEffect(sprung ? 1 : 0.86)
            .opacity(sprung ? 1 : 0)
            .blur(radius: sprung ? 0 : 4)
            .animation(.spring(response: 0.52, dampingFraction: 0.74).delay(glyphAppearDelay()), value: sprung)
            .onAppear {
                sprung = true
            }
        }
        .frame(height: 340)
        .shadow(color: Color.black.opacity(0.52), radius: 28, x: 0, y: 20)
        .shadow(color: Color.appAccent.opacity(0.12), radius: 22, x: 0, y: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.appPrimary.opacity(0.42), Color.appAccent.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        )
    }

    private func glyphAppearDelay() -> Double {
        switch glyph {
        case .plannerStack: return 0
        case .bookHeart: return 0.04
        case .sparkTrail: return 0.06
        }
    }

    @ViewBuilder
    private var glowAura: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.appAccent.opacity(0.12), lineWidth: 26)
            .blur(radius: 34)
            .opacity(0.55)
            .allowsHitTesting(false)
    }
}

private struct PlannerArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.64), Color.appBackground.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 40)
                .offset(y: -50)

            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.36), Color.appAccent.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 32)
                .offset(y: -6)

            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.appTextPrimary.opacity(0.88), Color.appAccent.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 4
                )
                .frame(height: 36)
                .offset(y: 34)

            HStack(spacing: 26) {
                Capsule(style: .continuous)
                    .fill(AppVisualGradients.primaryButton)
                    .frame(width: 8, height: 74)
                    .rotationEffect(.degrees(-24))
                    .offset(y: -6)
                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)

                Capsule(style: .continuous)
                    .fill(AppVisualGradients.accentSecondaryCTA)
                    .frame(width: 12, height: 88)
                    .rotationEffect(.degrees(26))
                    .offset(y: -4)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 5)
            }
        }
        .foregroundStyle(Color.appTextPrimary.opacity(0.92))
        .drawingGroup(opaque: false)
    }
}

private struct BookHeartArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppVisualGradients.mutedChipFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppVisualGradients.cardBorder, lineWidth: 0.95)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, y: 8)
                .frame(width: 190, height: 125)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.55), Color.appAccent.opacity(0.38)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 6)
                .offset(y: -32)

            VStack(spacing: 10) {
                Capsule(style: .continuous)
                    .fill(Color.appTextSecondary.opacity(0.85))
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                Capsule(style: .continuous)
                    .fill(Color.appTextSecondary.opacity(0.55))
                    .frame(height: 4)
                    .padding(.horizontal, 62)
                Capsule(style: .continuous)
                    .fill(Color.appTextSecondary.opacity(0.4))
                    .frame(height: 4)
                    .padding(.horizontal, 74)
            }
            .offset(y: -2)

            Image(systemName: "heart.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(AppVisualGradients.primaryButton)
                .shadow(color: Color.black.opacity(0.38), radius: 16, y: 9)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .offset(x: -1.5, y: -2)
                        .blendMode(.screen)
                )
        }
        .drawingGroup(opaque: false)
    }
}

private struct SparkTrailArtwork: View {
    var body: some View {
        ZStack {
            ForEach(0 ..< 4, id: \.self) { index in
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.appAccent.opacity(Double(4 - index) * 0.18),
                                Color.appPrimary.opacity(Double(4 - index) * 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: CGFloat(10 - index * 2)
                    )
                    .frame(width: CGFloat(170 - index * 38), height: CGFloat(170 - index * 38))
                    .offset(x: CGFloat(index * 14 - 26), y: CGFloat(index * 8 - 20))
                    .blur(radius: CGFloat(index))
            }

            Image(systemName: "sparkles")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.45), radius: 22, y: 8)

            Capsule(style: .continuous)
                .fill(AppVisualGradients.segmentedTrack)
                .frame(height: 5)
                .offset(y: -70)

            Capsule(style: .continuous)
                .fill(AppVisualGradients.accentSecondaryCTA)
                .frame(width: 120, height: 5)
                .rotationEffect(.degrees(-18))
                .offset(y: 64)

            Image(systemName: "lock.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.appTextPrimary.opacity(0.55))
                .padding(22)
                .background(
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
                .offset(y: 16)
                .opacity(0.85)
        }
        .drawingGroup(opaque: false)
    }
}
