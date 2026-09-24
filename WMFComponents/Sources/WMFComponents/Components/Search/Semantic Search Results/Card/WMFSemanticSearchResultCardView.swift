import SwiftUI

struct WMFSemanticSearchResultCardView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSemanticSearchResultViewModel
    @Environment(\.displayScale) private var displayScale

    private static let thumbnailSize: CGFloat = 32

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var hairline: CGFloat {
        max(1.0 / displayScale, 0.5)
    }

    // On sepia the card sits on the paper color: the link blue does not pass AA contrast on
    // the mid background there. The other themes keep the mid background so the card stands out.
    private var cardBackground: UIColor {
        theme == .sepia ? theme.paperBackground : theme.midBackground
    }

    var body: some View {
        Button(action: viewModel.readInArticle) {
            VStack(alignment: .leading, spacing: WMFSpacing.small) {
                passage
                articleRow
                Divider()
                    .background(Color(theme.newBorder))
                    .frame(height: hairline)
                attributionRow
            }
            .padding(WMFSpacing.large)
            .background(Color(cardBackground))
            .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge))
            .overlay(
                RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge)
                    .stroke(Color(theme.newBorder), lineWidth: hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, viewModel.isRightToLeft ? .rightToLeft : .leftToRight)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.semanticSearchResultCard)
        .onAppear {
            viewModel.loadDetailsIfNeeded()
        }
    }

    private var passage: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
            passageText
                .lineLimit(WMFSemanticSearchResultViewModel.passageLineLimit)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(viewModel.passageText)
            callToActionText
        }
    }

    private var passageFont: UIFont {
        WMFFont.for(.callout)
    }

    private var callToActionFont: UIFont {
        WMFFont.for(.mediumFootnote)
    }

    private var callToActionText: Text {
        Text(viewModel.localizedStrings.readInArticleTitle)
            .font(Font(callToActionFont))
            .foregroundColor(Color(theme.secondaryText))
    }

    /// The passage opens with a large quotation mark in the first line.
    /// The system cuts it at the line limit.
    private var passageText: Text {
        let font = passageFont
        let quotationMarkImage = viewModel.quotationMarkImage(font: font, color: theme.text)
        return Text(Image(uiImage: quotationMarkImage))
        + Text(
            viewModel.attributedPassage(
                font: font,
                textColor: theme.text,
                highlightColor: theme.editorMatchBackground,
                highlightTextColor: theme.editorMatchForeground,
                linkColor: theme.link
            )
        )
    }

    private var articleRow: some View {
        HStack(spacing: WMFSpacing.small) {
            if let thumbnail = viewModel.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.medium))
                    .accessibilityHidden(true)
            }
            Text(viewModel.articlePath)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.text))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, WMFSpacing.small)
    }

    private var attributionRow: some View {
        HStack(spacing: WMFSpacing.large) {
            if let contributorsText = viewModel.contributorsText {
                attributionLabel(symbol: .person2Fill, text: contributorsText)
            }
            if let referencesText = viewModel.referencesText {
                attributionLabel(symbol: .booksVerticalFill, text: referencesText)
            }
            if let lastUpdatedText = viewModel.lastUpdatedText {
                attributionLabel(symbol: .clockFill, text: lastUpdatedText, accessibilityText: viewModel.lastUpdatedAccessibilityText)
            }
        }
        .frame(minHeight: WMFSpacing.large)
    }

    private func attributionLabel(symbol: WMFSFSymbolIcon, text: String, accessibilityText: String? = nil) -> some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: symbol, font: .caption1) ?? UIImage())
                .foregroundStyle(Color(theme.secondaryText))
                .accessibilityHidden(true)
            Text(text)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.secondaryText))
                .accessibilityLabel(accessibilityText ?? text)
        }
    }
}
