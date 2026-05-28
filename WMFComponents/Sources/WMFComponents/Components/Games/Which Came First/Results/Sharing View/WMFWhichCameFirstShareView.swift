import SwiftUI
import WMFData

// MARK: - Share View

public struct WMFWhichCameFirstShareView: View {

    @ObservedObject var viewModel: WMFWhichCameFirstShareViewModel
    let theme: WMFTheme

    private let viewWidth: CGFloat = 393
    private let viewHeight: CGFloat = 627

    public init(viewModel: WMFWhichCameFirstShareViewModel, theme: WMFTheme = WMFTheme.light) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.paperBackground)
            VStack(alignment: .leading, spacing: 0) {

                Image("wikipedia", bundle: .module)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 28)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(uiColor: theme.text))
                    .padding(.top, 28)
                    .padding(.bottom, 32)

                scoreCard
                    .padding(.horizontal, 20)

                Text(viewModel.topicsIncludedTitle)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                VStack(spacing: 0) {
                    ForEach(viewModel.articles, id: \.title) { article in
                        articleRow(article)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(width: viewWidth, height: viewHeight)
        .clipped()
    }

    // MARK: - Article Row

    // This intentionally does not use `WMFAsyncPageRow`, because this view is rendered to an image via
    // `ImageRenderer` which is synchronous, any async fetches would not complete in time and the row would appear empty.
    private func articleRow(_ article: WMFWhichCameFirstShareViewModel.ArticleItem) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .lineLimit(1)
                if let description = article.description {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                        .lineLimit(1)
                }
            }
            Spacer()
            if let image = article.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 22) {
            Text(viewModel.scoreSummaryText)
                .font(Font(WMFFont.for(.georgiaTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            resultIcons
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: WMFColor.yellow600), lineWidth: 2)
        )
    }

    // MARK: - Result Icons

    private var resultIcons: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.questionResults.enumerated()), id: \.offset) { _, result in
                resultIcon(isCorrect: result.isCorrect)
            }
        }
    }

    private func resultIcon(isCorrect: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isCorrect ? Color(uiColor: WMFColor.green700) : Color(uiColor: WMFColor.red700))
                .frame(width: 22, height: 22)

            if let icon = WMFSFSymbolIcon.for(symbol: isCorrect ? .checkmark : .xMark, font: .boldCaption1) {
                Image(uiImage: icon)
                    .foregroundColor(Color(uiColor: WMFColor.white))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WMFWhichCameFirstShareView(
        viewModel: WMFWhichCameFirstShareViewModel(
            score: 1,
            totalQuestions: 5,
            questionResults: [false, true, true, true, true],
            articles: [
                .init(title: "Jawan (film)", description: "2023 Indian action film"),
                .init(title: "2023 Asia Cup", description: "Cricket tournament"),
                .init(title: "Coco Gauff", description: "American tennis player"),
                .init(title: "Danny Masterson", description: "American actor"),
                .init(title: "Asia Cup", description: "Cricket tournament")
            ]
        )
    )
}
