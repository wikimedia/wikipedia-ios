import SwiftUI

struct WMFYearInReviewSlideLocationView: View {
    let viewModel: WMFYearInReviewSlideLocationViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideLocationViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct WMFYearInReviewSlideLocationViewContent: View {
    let viewModel: WMFYearInReviewSlideLocationViewModel
    
    var body: some View {
        Text(viewModel.title)
    }
}
