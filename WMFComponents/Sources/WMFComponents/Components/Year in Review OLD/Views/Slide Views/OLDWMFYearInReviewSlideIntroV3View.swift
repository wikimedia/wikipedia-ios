import SwiftUI
import WMFData

struct OLDWMFYearInReviewSlideIntroV3View: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let viewModel: OLDWMFYearInReviewIntroV3ViewModel
    @Binding var isPopulatingReport: Bool

    init(viewModel: OLDWMFYearInReviewIntroV3ViewModel, isPopulatingReport: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPopulatingReport = isPopulatingReport
    }

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    var body: some View {

        ZStack(alignment: .bottom) {
            OLDWMFYearInReviewScrollView(scrollViewContents: OLDWMFYearInReviewSlideIntroV3ViewContent(viewModel: viewModel))

            VStack(spacing: 16) {
                Text(viewModel.footer)
                    .multilineTextAlignment(.center)
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))

                WMFLargeButtonLoading(style: .primary, title: viewModel.primaryButtonTitle, icon: nil, isLoading: $isPopulatingReport) {
                        viewModel.tappedPrimaryButton()
                }

                WMFLargeButton(style: .neutral, title: viewModel.secondaryButtonTitle) {
                    viewModel.tappedSecondaryButton()
                }

            }
            .padding(EdgeInsets(top: 12, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
            .background {
                    Color(appEnvironment.theme.midBackground).ignoresSafeArea()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.onAppear()
        }
    }
}


fileprivate struct OLDWMFYearInReviewSlideIntroV3ViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: OLDWMFYearInReviewIntroV3ViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    fileprivate init(viewModel: OLDWMFYearInReviewIntroV3ViewModel) {
        self.viewModel = viewModel
    }

    @ScaledMetric private var bottomInset = 135.0

    var body: some View {

        VStack(spacing: 16) {
            VStack(spacing: 16) {
                ZStack {
                    Image(viewModel.gifName, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    WMFGIFImageView(viewModel.gifName)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(viewModel.altText)
            }

                VStack(alignment: .center, spacing: 16) {
                    Text(viewModel.title)
                        .multilineTextAlignment(.center)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundColor(Color(uiColor: theme.text))
                    Text(viewModel.subtitle)
                        .multilineTextAlignment(.center)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundColor(Color(uiColor: theme.text))
                }
                .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: bottomInset, trailing: sizeClassPadding))
        }
    }
}
