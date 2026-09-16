import SwiftUI

struct WMFYearInReviewToolbarView: View {

    @ObservedObject var viewModel: WMFYearInReviewViewModel

    let contentColor: Color
    let donateSourceRect: @MainActor () -> CGRect

    private var tint: Color { contentColor }

    var body: some View {
        HStack {
            if viewModel.currentSlide?.showsShareButton ?? false {
                Button(action: viewModel.tappedShare) {
                    Label {
                        Text(viewModel.localizedStrings.shareButtonTitle)
                    } icon: {
                        if let icon = WMFSFSymbolIcon.for(symbol: .share) {
                            Image(uiImage: icon)
                        }
                    }
                }
                .foregroundStyle(tint)
            }

            Spacer()

            if viewModel.currentSlide?.showsDonateButton ?? false {
                Button {
                    viewModel.tappedDonate(sourceRect: donateSourceRect)
                } label: {
                    if viewModel.isLoadingDonate {
                        ProgressView()
                    } else {
                        Label {
                            Text(viewModel.localizedStrings.donateButtonTitle)
                        } icon: {
                            if let icon = WMFSFSymbolIcon.for(symbol: .heartFilled) {
                                Image(uiImage: icon)
                            }
                        }
                    }
                }
                .foregroundStyle(tint)
            }
        }
        .font(Font(WMFFont.for(.semiboldHeadline)))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
