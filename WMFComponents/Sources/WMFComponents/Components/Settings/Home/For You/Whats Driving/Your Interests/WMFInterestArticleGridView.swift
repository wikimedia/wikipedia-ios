// TODO: This is temporary UI — article grid and card views are placeholders pending final design.

import SwiftUI
import WMFData

struct WMFInterestArticleGridView: View {

    let articles: [WMFRandomArticle]
    let theme: WMFTheme

    private var columns: (left: [WMFRandomArticle], right: [WMFRandomArticle]) {
        var left: [WMFRandomArticle] = []
        var right: [WMFRandomArticle] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for article in articles {
            if leftHeight <= rightHeight {
                left.append(article)
                leftHeight += estimatedHeight(for: article)
            } else {
                right.append(article)
                rightHeight += estimatedHeight(for: article)
            }
        }
        return (left, right)
    }

    private func estimatedHeight(for article: WMFRandomArticle) -> CGFloat {
        let imageHeight: CGFloat = article.thumbnail?.url != nil ? 100 : 0
        let titleLines = max(1, Int(ceil(Double((article.displayTitle ?? article.title).count) / 18.0)))
        let titleHeight = CGFloat(titleLines) * 20
        let descriptionHeight: CGFloat
        if let desc = article.description {
            let lines = max(1, Int(ceil(Double(desc.count) / 20.0)))
            descriptionHeight = CGFloat(lines) * 16
        } else {
            descriptionHeight = 0
        }
        return imageHeight + titleHeight + descriptionHeight + 32 // 32 for padding + spacing
    }

    var body: some View {
        let cols = columns
        HStack(alignment: .top, spacing: 12) {
            column(cols.left)
            column(cols.right)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func column(_ items: [WMFRandomArticle]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items, id: \.pageid) { article in
                WMFInterestArticleCardView(
                    viewModel: WMFInterestArticleCardViewModel(article: article),
                    theme: theme
                )
            }
        }
    }
}

private struct WMFInterestArticleCardView: View {

    @ObservedObject var viewModel: WMFInterestArticleCardViewModel
    let theme: WMFTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let uiImage = viewModel.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
                    .contentShape(Rectangle())
            }
            VStack(alignment: .leading, spacing: 4) {
                WMFHtmlText(html: viewModel.title, styles: HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.italicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 1))
                if let description = viewModel.description {
                    Text(description)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(uiColor: theme.border), lineWidth: 0.5)
        )
        .onAppear {
            viewModel.loadImageIfNeeded()
        }
    }
}
