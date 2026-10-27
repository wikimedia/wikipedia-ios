import SwiftUI

public struct WMFYearInReviewAnnouncementView: View {

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

            exploreButton
                .padding(.top, 0)
            Spacer()
        }
        .background(Color(uiColor: WMFTheme.light.paperBackground))
    }

    /// Same as the primary donate button on the slides: a spinner replaces the title while it loads.
    private var exploreButton: some View {
        ZStack {
            WMFSmallButton(
                configuration: .init(style: .primary),
                title: viewModel.localizedStrings.exploreButtonTitle,
                forceBackgroundColor: WMFTheme.light.link,
                forceForegroundColor: WMFTheme.light.paperBackground,
                action: viewModel.tappedExplore
            )
            .opacity(viewModel.isLoadingExplore ? 0 : 1)
            .disabled(viewModel.isLoadingExplore)

            if viewModel.isLoadingExplore {
                ProgressView()
            }
        }
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
