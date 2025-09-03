import SwiftUI

struct WMFYearInReviewContributionSlideView: View {
    let viewModel: WMFYearInReviewContributorSlideViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    init(viewModel: WMFYearInReviewContributorSlideViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WMFYearInReviewScrollView(scrollViewContents: Text("Text"))
            
            VStack {
                WMFLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle) {
                    withAnimation(.easeInOut(duration: 0.75)) {
                        viewModel.tappedPrimaryButton()
                    }
                }
                
                WMFLargeButton(configuration: .secondary, title: viewModel.secondaryButtonTitle) {
                    viewModel.tappedSecondaryButton()
                }
                
            }
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
