import SwiftUI
import WMFData


// MARK: - Share View

public struct WMFWhichCameFirstShareView: View {

    @ObservedObject var viewModel: WMFWhichCameFirstShareViewModel

    // Fixed sizing for image sharing
    private let viewWidth: CGFloat = 393
    private let viewHeight: CGFloat = 627

    public init(viewModel: WMFWhichCameFirstShareViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: WMFColor.white)
            VStack(alignment: .leading, spacing: 0) {

                Image("wikipedia", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 28)
                    .padding(.bottom, 32)

                scoreCard
                    .padding(.horizontal, 20)

                Text(viewModel.topicsIncludedTitle)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: WMFColor.gray700))
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                VStack(spacing: 0) {
                    ForEach(viewModel.articleTitles, id: \.self) { title in
                        WMFAsyncPageRow(
                            viewModel: WMFAsyncPageRowViewModel(
                                id: title,
                                title: title,
                                projectID: viewModel.projectID,
                                iconAccessibilityLabel: ""
                            )
                        )
                        .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(width: viewWidth, height: viewHeight)
        .clipped()
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 22) {
            Text(viewModel.scoreSummaryText)
                .font(Font(WMFFont.for(.georgiaTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
                .foregroundColor(Color(uiColor: WMFColor.gray700))
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
            articleTitles: ["Jawan (film)", "2023 Asia Cup", "Asia Cup", "Coco Gauff", "Danny Masterson"],
            projectID: "wikipedia_en"
        )
    )
}
