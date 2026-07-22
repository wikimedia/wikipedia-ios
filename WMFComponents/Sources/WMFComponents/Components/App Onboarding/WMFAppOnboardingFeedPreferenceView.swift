import SwiftUI
import WMFData

struct WMFAppOnboardingFeedPreferenceView: View {

    @ObservedObject var viewModel: WMFAppOnboardingFeedPreferenceViewModel
    let theme: WMFTheme

    // The container caps dynamicTypeSize for the whole onboarding flow; fonts resolve
    // against the capped value via WMFFont.for(_:sized:).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Scaled with Dynamic Type so text inside the cards has room to grow; all values scale
    // by the same factor, preserving their ratios. The cards row swipes horizontally either way.
    @ScaledMetric private var cardWidth: CGFloat = 170
    @ScaledMetric private var cardHeight: CGFloat = 220

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.title)
                    .font(Font(WMFFont.for(.boldTitle3, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                optionRow(
                    title: viewModel.communityOptionTitle,
                    option: .community,
                    isEnabled: true,
                    accessibilityIdentifier: AccessibilityIdentifiers.Onboarding.communityOptionButton
                )
                if viewModel.isCommunityLoading {
                    loadingRow
                } else {
                    cardsRow(cards: viewModel.communityCards)
                }

                optionRow(
                    title: viewModel.personalizedOptionTitle,
                    option: .personalized,
                    isEnabled: viewModel.isPersonalizedAvailable,
                    accessibilityIdentifier: AccessibilityIdentifiers.Onboarding.personalizedOptionButton
                )
                .padding(.top, 16)

                if viewModel.isPersonalizedLoading {
                    loadingRow
                } else if viewModel.isPersonalizedAvailable {
                    cardsRow(cards: viewModel.personalizedCards)
                } else {
                    Text(viewModel.personalizedDisabledExplanation)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, WMFAppOnboardingView.toolbarContentInset)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.feedPreferenceView)
    }

    private func optionRow(title: String, option: WMFHomeFeedSeeFirst, isEnabled: Bool, accessibilityIdentifier: String) -> some View {
        let isSelected = viewModel.selection == option
        return HStack(spacing: 12) {
            radioIcon(isSelected: isSelected, isEnabled: isEnabled)
            Text(title)
                .font(Font(WMFFont.for(.boldCallout, sized: dynamicTypeSize)))
                .foregroundStyle(Color(uiColor: isEnabled ? theme.text : theme.secondaryText))
            Spacer()
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            // The view model guards the personalized option while its data is loading/unavailable
            withAnimation {
                viewModel.select(option)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    // Same footprint as a cards row so the layout doesn't jump when content arrives
    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(height: cardHeight)
    }

    @ScaledMetric private var radioSize: CGFloat = 24

    @ViewBuilder
    private func radioIcon(isSelected: Bool, isEnabled: Bool) -> some View {
        if isSelected, let checkmark = WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill) {
            Image(uiImage: checkmark)
                .resizable()
                .scaledToFit()
                .frame(width: radioSize, height: radioSize)
                .foregroundStyle(Color(uiColor: theme.link))
        } else {
            Circle()
                .strokeBorder(Color(uiColor: isEnabled ? theme.secondaryText : theme.border), lineWidth: 2)
                .frame(width: radioSize, height: radioSize)
        }
    }

    // The row scrolls horizontally; the cards themselves are preview-only (no tap handling)
    private func cardsRow(cards: [WMFAppOnboardingPreviewCardViewModel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cards) { card in
                    WMFAppOnboardingPreviewCardView(viewModel: card, theme: theme)
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Non-interactive sample article card: image (when available), optional topic pill, title, description.
/// Fixed height; without an image the content pushes to the top and the pill moves above the title.
private struct WMFAppOnboardingPreviewCardView: View {

    @ObservedObject var viewModel: WMFAppOnboardingPreviewCardViewModel
    let theme: WMFTheme

    // Scales with Dynamic Type alongside the card's outer frame, keeping the image band's
    // proportion of the card constant.
    @ScaledMetric private var imageHeight: CGFloat = 100

    // Capped by the onboarding container; fonts resolve against the capped value.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let uiImage = viewModel.uiImage {
                // The container drives layout; scaledToFill images would otherwise report
                // their own width and inflate the card beyond its fixed size
                Color.clear
                    .frame(height: imageHeight)
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        if let pill = viewModel.topicPill {
                            topicPillView(pill)
                                .padding(8)
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                if viewModel.uiImage == nil, let pill = viewModel.topicPill {
                    topicPillView(pill)
                }
                Text(viewModel.title)
                    .font(Font(WMFFont.for(.semiboldHeadline, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .lineLimit(2)
                if let description = viewModel.description {
                    Text(description)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }
            }
            .padding(8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(uiColor: theme.newBorder), lineWidth: 1)
        )
        .onAppear {
            viewModel.loadImageIfNeeded()
        }
    }

    private func topicPillView(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.mediumFootnote, sized: dynamicTypeSize)))
            .foregroundStyle(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(uiColor: theme.link))
            )
    }
}
