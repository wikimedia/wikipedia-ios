import SwiftUI

struct WMFYearInReviewSlideLocationView: View {
    @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideLocationViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                viewModel.fakeDataCall()
            }
    }
}

fileprivate struct WMFYearInReviewSlideLocationViewContent: View {
    @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .background(Color(theme.midBackground))
        } else {
            Text(viewModel.title)
        }
    }
}
