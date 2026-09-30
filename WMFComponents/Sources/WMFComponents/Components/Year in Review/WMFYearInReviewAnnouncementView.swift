import SwiftUI

public struct WMFYearInReviewAnnouncementView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewAnnouncementViewModel

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFYearInReviewAnnouncementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            animation
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The navigation bar is see-through, so the artwork runs under it.
                .ignoresSafeArea(.container, edges: .top)

            WMFLargeButton(
                style: .primary,
                title: viewModel.localizedStrings.exploreButtonTitle,
                action: viewModel.tappedExplore
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: theme.paperBackground))
    }

    // MARK: - Artwork

    @ViewBuilder
    private var animation: some View {
        if let animation = viewModel.animation {
            WMFRiveView(
                animation,
                text: viewModel.riveText,
                numbers: viewModel.riveNumbers,
                accessibilityLabel: viewModel.localizedStrings.animationAccessibilityLabel
            )
            // Text inside the artwork is not read, so VoiceOver gets the body here.
            .accessibilityValue(Text(viewModel.localizedStrings.body))
        } else {
            // Shows until the .riv file is added.
            Text(viewModel.localizedStrings.animationAccessibilityLabel)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}
