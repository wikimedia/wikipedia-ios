import SwiftUI

public struct WMFYearInReviewAnnouncementView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewAnnouncementViewModel

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
                forceBackgroundColor: WMFTheme.light.link, forceForegroundColor: WMFTheme.light.paperBackground,
                action: viewModel.tappedExplore
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: WMFTheme.light.paperBackground))
    }

    // MARK: - Artwork

    private var animation: some View {
        WMFRiveView(
            viewModel.animation,
            text: viewModel.riveText,
            numbers: viewModel.riveNumbers,
            accessibilityLabel: viewModel.localizedStrings.animationAccessibilityLabel,
            readBool: viewModel.lightContentFlag,
            textFits: viewModel.textFits,
            onReadBool: { [weak viewModel] isLight in
                viewModel?.didReadLightContentFlag(isLight)
            }
        )
        // Text inside the artwork is not read, so VoiceOver gets the body here.
        .accessibilityValue(Text(viewModel.localizedStrings.body))
    }
}
