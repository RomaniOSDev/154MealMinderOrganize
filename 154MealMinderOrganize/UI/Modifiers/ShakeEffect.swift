import SwiftUI

private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    private let amount = 12.0

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 2), y: 0))
    }
}

extension View {
    func shake(times: CGFloat) -> some View {
        modifier(ShakeEffect(shakes: times))
            .animation(.easeInOut(duration: 0.08), value: times)
    }
}
