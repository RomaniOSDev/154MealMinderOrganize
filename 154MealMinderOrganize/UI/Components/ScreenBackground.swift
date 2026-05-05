import SwiftUI

private struct HoneycombPatternView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 28
            let hexW = spacing * 1.732
            var y: CGFloat = 0
            var rowIndex = 0
            while y < size.height + spacing {
                var x = rowIndex.isMultiple(of: 2) ? -spacing : -spacing / 2
                while x < size.width + hexW {
                    let rectPath = CGRect(x: x, y: y, width: spacing * 1.05, height: spacing * 0.92)
                    let path = Path(roundedRect: rectPath.insetBy(dx: 8, dy: 8), cornerRadius: 4)
                    ctx.stroke(path, with: .color(Color.appPrimary.opacity(0.07)), lineWidth: 1)
                    x += hexW / 2
                }
                y += spacing * 1.06
                rowIndex += 1
            }
        }
        .allowsHitTesting(false)
    }
}

struct ScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appSurface.opacity(0.55),
                    Color.appBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.09),
                    Color.appAccent.opacity(0.045),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    Color.black.opacity(0.38),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 520
            )
            .blendMode(.multiply)
            .opacity(0.75)

            HoneycombPatternView()
            content
        }
        .background(Color.appBackground)
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackgroundModifier())
    }

    /// Hides Form/List/system table chrome that defaults to white in light mode.
    func themedGroupedSurface() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }

    func sheetPresentationChrome() -> some View {
        presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
    }
}
