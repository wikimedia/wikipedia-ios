import SwiftUI
import UIKit

// MARK: - Lottie bridge
//
// Wraps Lottie's `LottieAnimationView` (Lottie 4.x / `import Lottie`) in a
// UIViewRepresentable so it can be dropped into SwiftUI layouts.
//
// Lottie is already a dependency of the wikipedia-ios repo (used in existing
// features). Add this file to the WMFComponents target alongside those usages.
//
// If Lottie is not yet available in the target you're working in, see the
// PLACEHOLDER section at the bottom for a SwiftUI-only fallback that is used
// automatically when the LOTTIE_AVAILABLE flag is absent.

#if canImport(Lottie)
import Lottie

public struct WMFLottieView: UIViewRepresentable {

    public enum LoopMode {
        case loop
        case playOnce
        case bounce

        fileprivate var lottieMode: Lottie.LottieLoopMode {
            switch self {
            case .loop:      return .loop
            case .playOnce:  return .playOnce
            case .bounce:    return .autoReverse
            }
        }
    }

    private let animationName: String
    private let loopMode: LoopMode
    private let bundle: Bundle

    public init(animationName: String,
                loopMode: LoopMode = .loop,
                bundle: Bundle = .main) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.bundle = bundle
    }

    public func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName, bundle: bundle)
        view.contentMode = .scaleAspectFill
        view.loopMode = loopMode.lottieMode
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return view
    }

    public func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }
}

#else

// MARK: - Placeholder (no Lottie import available)
//
// Renders a pulsing gradient circle so the layout looks reasonable in Xcode
// Previews or simulator builds where the Lottie package isn't linked yet.

public struct WMFLottieView: View {

    private let animationName: String
    private let loopMode: _LoopMode

    @State private var pulsing = false

    public enum _LoopMode { case loop, playOnce, bounce }

    public init(animationName: String, loopMode: _LoopMode = .loop, bundle: Bundle = .main) {
        self.animationName = animationName
        self.loopMode = loopMode
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .scaleEffect(pulsing ? 1.15 : 0.85)
                    .opacity(pulsing ? 0.6 : 0.2)
                    .animation(
                        .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: pulsing
                    )

                // Debug label visible in previews only
                #if DEBUG
                Text("[\(animationName)]")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                #endif
            }
        }
        .onAppear { pulsing = true }
    }
}

#endif
