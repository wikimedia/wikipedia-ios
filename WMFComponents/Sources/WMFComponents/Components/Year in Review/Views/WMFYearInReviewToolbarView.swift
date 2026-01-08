import SwiftUI

struct WMFYearInReviewToolbarView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    var needShareButton: Bool

    init(viewModel: WMFYearInReviewViewModel, needShareButton: Bool = true) {
        self.viewModel = viewModel
        self.needShareButton = needShareButton
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
                viewModel.tappedShare()
            }) {
                HStack(alignment: .center, spacing: 6) {
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .share, font: .semiboldHeadline) {
                        Image(uiImage: uiImage)
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                    Text(viewModel.localizedStrings.shareButtonTitle)
                        .foregroundStyle(Color(uiColor: theme.link))
                }
                .font(Font(WMFFont.for(.semiboldHeadline)))
            }
            .frame(maxWidth: .infinity)
            .opacity(needShareButton ? 1 : 0)
            .allowsHitTesting(needShareButton)
            .accessibilityHidden(!needShareButton)

            Spacer()
            HStack(spacing: 9) {
                ForEach(0..<viewModel.slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentSlideIndex ? Color(uiColor: theme.link) : Color(uiColor: theme.link.withAlphaComponent(0.3)))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.tappedNext()
                }
            }) {
                let text = viewModel.isLastSlide ? viewModel.localizedStrings.finishButtonTitle : viewModel.localizedStrings.nextButtonTitle
                Text(text)
                    .foregroundStyle(Color(uiColor: theme.link))
                    .font(Font(WMFFont.for(.semiboldHeadline)))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

