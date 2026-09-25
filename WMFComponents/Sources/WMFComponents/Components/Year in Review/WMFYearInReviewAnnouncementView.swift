import SwiftUI

public struct WMFYearInReviewAnnouncementView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewAnnouncementViewModel
    @AccessibilityFocusState private var isInfoCardFocused: Bool

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
            footer
        }
        .overlay(alignment: .topLeading) {
            closeButton
        }
        .overlay(alignment: .bottom) {
            if viewModel.isShowingInfo {
                infoCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isShowingInfo)
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
        } else {
            // Shows until the .riv file is added.
            Text(viewModel.localizedStrings.animationAccessibilityLabel)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 24) {
            Button(action: viewModel.tappedInfo) {
                bodyText
                    .font(Font(WMFFont.for(.georgiaCallout)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.localizedStrings.body)
            .accessibilityHint(viewModel.localizedStrings.infoButtonAccessibilityHint)

            Button(action: viewModel.tappedExplore) {
                Text(viewModel.localizedStrings.exploreButtonTitle)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .padding(.horizontal, 20)
            }
            .buttonStyle(CapsuleButtonStyle(kind: .primary, layout: .hug, theme: theme))
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    /// The body copy with the info icon at the end of the last line.
    private var bodyText: Text {
        let text = Text(viewModel.localizedStrings.body)
        guard let icon = WMFSFSymbolIcon.for(symbol: .infoCircleFill, font: .georgiaCallout) else {
            return text
        }
        return Text("\(text) \(Image(uiImage: icon).renderingMode(.template))")
    }

    // MARK: - Close

    private var closeButton: some View {
        Button(action: viewModel.tappedClose) {
            closeIcon
                .foregroundStyle(Color(uiColor: viewModel.closeButtonColor))
                .frame(width: 44, height: 44)
        }
        .padding(8)
        .accessibilityLabel(viewModel.localizedStrings.closeButtonAccessibilityLabel)
    }

    @ViewBuilder
    private var closeIcon: some View {
        if let image = WMFSFSymbolIcon.for(symbol: .close, font: .boldTitle3) {
            Image(uiImage: image)
                .renderingMode(.template)
        }
    }

    // MARK: - Info card

    /// Uses the theme's text and background colors swapped, so the card stands out in any theme.
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.localizedStrings.infoTitle)
                .font(Font(WMFFont.for(.boldSubheadline)))
                .foregroundStyle(Color(uiColor: theme.paperBackground))

            Text(viewModel.localizedStrings.infoBody)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundStyle(Color(uiColor: theme.paperBackground))

            HStack(spacing: 24) {
                Button(viewModel.localizedStrings.learnMoreButtonTitle, action: viewModel.tappedLearnMore)
                Button(viewModel.localizedStrings.gotItButtonTitle, action: viewModel.tappedGotIt)
            }
            .buttonStyle(.plain)
            .font(Font(WMFFont.for(.semiboldSubheadline)))
            .foregroundStyle(Color(uiColor: theme.link))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: theme.text))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityFocused($isInfoCardFocused)
        .onAppear {
            isInfoCardFocused = true
        }
    }
}
