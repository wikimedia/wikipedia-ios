import SwiftUI

/// The last screen of Year in Review: a thank you, an optional share button, and a row of cards.
public struct WMFYearInReviewEndView: View {

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    @ObservedObject private var viewModel: WMFYearInReviewEndViewModel

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFYearInReviewEndViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                WMFCardCarouselView(items: viewModel.cards) { card in
                    cardView(card)
                }
            }
            .padding(.vertical, 24)
        }
        .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Text(viewModel.headline.localizedUppercase)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Text(viewModel.body)
                .font(Font(WMFFont.for(.body)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            if viewModel.showsShareHighlights {
                ctaButton(title: viewModel.shareHighlightsButtonTitle, systemImage: "square.and.arrow.up") {
                    viewModel.didTapShareHighlights?()
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Cards

    private func cardView(_ card: WMFYearInReviewEndViewModel.Card) -> some View {
        VStack(spacing: 16) {
            Text(card.title.localizedUppercase)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Text(card.body)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            ctaButton(title: card.buttonTitle) {
                viewModel.didTap(card)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: theme.midBackground))
        )
    }

    // MARK: - Button

    private func ctaButton(title: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Font(WMFFont.for(.boldCallout)))
            }
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color(uiColor: theme.link)))
        }
        .buttonStyle(.plain)
    }
}
