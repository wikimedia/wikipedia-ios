import SwiftUI

struct OLDWMFYearInReviewHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: OLDWMFYearInReviewViewModel

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    init(viewModel: OLDWMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if viewModel.shouldShowTopNavDonateButton {
                OLDWMFYearInReviewDonateButton(viewModel: viewModel)
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
