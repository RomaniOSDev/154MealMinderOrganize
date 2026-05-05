import SwiftUI

// MARK: - Gradients shared across elevated surfaces & CTAs

enum AppVisualGradients {
    static let elevatedCardFill = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.99),
            Color.appSurface.opacity(0.87),
            Color.appBackground.opacity(0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBorder = LinearGradient(
        colors: [
            Color.appPrimary.opacity(0.38),
            Color.appAccent.opacity(0.26),
            Color.appPrimary.opacity(0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Soft fill for segmented chips / helper pills.
    static let mutedChipFill = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.92),
            Color.appSurface.opacity(0.74)
        ],
        startPoint: .top,
        endPoint: .bottomTrailing
    )

    static func specularRim(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.058),
                        Color.white.opacity(0.012),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }

    static let primaryButton = LinearGradient(
        colors: [
            Color.appPrimary,
            Color.appPrimary.opacity(0.78),
            Color.appAccent.opacity(0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryButtonPressed = LinearGradient(
        colors: [
            Color.appAccent.opacity(0.95),
            Color.appPrimary.opacity(0.82)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentSecondaryCTA = LinearGradient(
        colors: [
            Color.appAccent.opacity(0.96),
            Color.appAccent.opacity(0.74),
            Color.appPrimary.opacity(0.52)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let insetWell = LinearGradient(
        colors: [
            Color.appBackground.opacity(0.62),
            Color.appSurface.opacity(0.28)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let segmentedTrack = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.88),
            Color.appSurface.opacity(0.64),
            Color.appBackground.opacity(0.52)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fabBurst = RadialGradient(
        colors: [
            Color.appPrimary.opacity(0.92),
            Color.appPrimary.opacity(0.74),
            Color.appAccent.opacity(0.62)
        ],
        center: .topLeading,
        startRadius: 4,
        endRadius: 48
    )
}

// MARK: - Elevation tiers

enum AppElevatedTier {
    case subtle
    case standard
    case prominent

    fileprivate var shadow: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .subtle: return (0.18, 9, 5)
        case .standard: return (0.32, 16, 12)
        case .prominent: return (0.44, 24, 16)
        }
    }

    fileprivate var strokeWidth: CGFloat {
        switch self {
        case .subtle: return 0.85
        case .standard: return 1.1
        case .prominent: return 1.25
        }
    }
}

// MARK: - Card chrome

private struct AppElevatedCardBackground: View {
    let cornerRadius: CGFloat
    var tier: AppElevatedTier = .standard

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppVisualGradients.elevatedCardFill)
            .overlay(
                AppVisualGradients.specularRim(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppVisualGradients.cardBorder, lineWidth: tier.strokeWidth)
            )
            .shadow(
                color: Color.black.opacity(tier.shadow.opacity),
                radius: tier.shadow.radius,
                x: 0,
                y: tier.shadow.y
            )
    }
}

extension View {
    /// Layered gradient fill, rim stroke, highlight, and drop shadow suitable for grouped content.
    func appElevatedCard(cornerRadius: CGFloat = 18, tier: AppElevatedTier = .standard) -> some View {
        background {
            AppElevatedCardBackground(cornerRadius: cornerRadius, tier: tier)
        }
    }

    /// Shallow embossed panel for segmented controls etc.
    func appConvexPanel(cornerRadius: CGFloat = 16) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppVisualGradients.segmentedTrack)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppVisualGradients.cardBorder.opacity(0.75), lineWidth: 1)
                AppVisualGradients.specularRim(cornerRadius: cornerRadius)
            }
            .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 10)
        }
    }

    /// Recessed strip for nested fields inside a larger card (step notes etc.).
    func appInsetWell(cornerRadius: CGFloat = 12) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppVisualGradients.insetWell)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.35),
                                    Color.appPrimary.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Floating buttons

extension View {
    func appFABGradientBackdrop() -> some View {
        background {
            ZStack {
                Circle()
                    .fill(AppVisualGradients.fabBurst)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .shadow(color: Color.black.opacity(0.48), radius: 18, x: 0, y: 11)
            .shadow(color: Color.appAccent.opacity(0.18), radius: 10, x: 0, y: 6)
        }
    }
}

// MARK: - Primary rounded CTA buttons (shared)

struct AppPrimaryRoundedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(Color.appBackground)
            .background(
                configuration.isPressed
                    ? AppVisualGradients.primaryButtonPressed
                    : AppVisualGradients.primaryButton
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0 : 0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.26 : 0.38),
                radius: configuration.isPressed ? 8 : 14,
                x: 0,
                y: configuration.isPressed ? 4 : 9
            )
            .shadow(
                color: Color.appAccent.opacity(configuration.isPressed ? 0 : 0.22),
                radius: configuration.isPressed ? 0 : 10,
                x: 0,
                y: 6
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: configuration.isPressed)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
