import SwiftUI

/// The final onboarding step: a full-screen Rive animation shown while the chosen feed loads.
/// No toolbar. Completes onboarding once the feed has loaded and the animation has looped at
/// least once (whichever takes longer).
struct WMFAppOnboardingLoadingView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    let theme: WMFTheme

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.loadingTitle)
                .font(Font(WMFFont.for(.boldTitle1, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

            WMFRiveView(viewModel.loadingAnimation)
                .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.loadingView)
        .onAppear {
            viewModel.completeAfterLoadingFeed(minimumDisplay: viewModel.loadingAnimationLoopDuration)
        }
    }
}
