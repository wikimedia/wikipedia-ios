import SwiftUI

struct WMFYearInReviewHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if viewModel.shouldShowTopNavDonateButton {
                WMFYearInReviewDonateButton(viewModel: viewModel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Image("W", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
                .foregroundColor(Color(theme.text))
                .accessibilityLabel(viewModel.localizedStrings.wIconAccessibilityLabel)
            Spacer()
            
            WMFLargeCloseButton(imageType: .plainX, action: {
                viewModel.tappedDone()
            })
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.bottom, 5)
        .padding([.top, .horizontal], 16)
    }
}
