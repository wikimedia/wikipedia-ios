import SwiftUI

public struct WMFYearInReviewSlideHighlightShareableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    public let viewModel: WMFYearInReviewSlideHighlightsViewModel

    public init(viewModel: WMFYearInReviewSlideHighlightsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: WMFColor.white)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                VStack {
                    Spacer(minLength: 0)

                    infoboxView
                        .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("wikipedia.org/year-in-review")
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: WMFColor.black))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .frame(width: 402, height: 847)
            
        }
        .overlay(
            Rectangle()
                .stroke(Color(WMFColor.gray300), lineWidth: 1)
        )
    }

    private var infoboxView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("#WikipediaYearInReview")
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundStyle(Color(uiColor: WMFColor.black))
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Image("globe_yir", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 196, height: 196)
                        .accessibilityHidden(true)

                    Text("Wikipedia logo")
                        .font(Font(WMFFont.for(.footnote)))
                        .foregroundStyle(Color(WMFColor.black))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                WMFYearInReviewInfoboxView(viewModel: viewModel.infoBoxViewModel)
                    .accessibilityElement(children: .contain)
            }
            .padding(16)
        }
        .background(Color(WMFColor.gray100))
        .overlay(
            Rectangle()
                .stroke(Color(WMFColor.gray300), lineWidth: 1)
        )
    }
}
