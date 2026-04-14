import SwiftUI

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
#if SKIP
        // Skip/Android: no `.glassEffect` / material stack; approximate card chrome for parity with iOS.
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            content
                .padding(14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
#else
        ZStack {
            if #available(macOS 26, iOS 26, *) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            content.padding(14)
        }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
#endif
    }
}
