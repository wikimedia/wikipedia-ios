import SwiftUI

// MARK: - Content Slide

/// Full-bleed immersive slide with Lottie animation + centred text overlay.
public struct WMFYiR2026ContentSlideView: View {

    let data: WMFYiR2026ContentSlideData

    @State private var textVisible = false

    public var body: some View {
        ZStack {
            // MARK: Background gradient (accent color fills entire screen)
            LinearGradient(
                colors: [
                    data.accentColor,
                    data.accentColor.opacity(0.6),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: Lottie animation (full bleed)
            // WMFLottieView self-resolves to the WMFComponents bundle — no bundle param needed.
            if let lottieName = data.lottieName {
                WMFLottieView(animationName: lottieName, loopMode: .loop)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // MARK: Bottom scrim for readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
            }
            .ignoresSafeArea()

            // MARK: Text — centred vertically
            VStack(spacing: 16) {
                Text(data.headline)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)

                Text(data.body)
                    .font(.system(size: 17, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 32)
            }
            .opacity(textVisible ? 1 : 0)
            .scaleEffect(textVisible ? 1 : 0.92)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: textVisible)
        }
        .onAppear { textVisible = true }
        .onDisappear { textVisible = false }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WMFYiR2026ContentSlideView(data: .init(
        lottieName: nil,
        accentColor: Color(red: 0.13, green: 0.35, blue: 0.63),
        headline: "4,200 Articles\nRead",
        body: "You were in the top 3% of Wikipedia readers globally."
    ))
}
#endif
