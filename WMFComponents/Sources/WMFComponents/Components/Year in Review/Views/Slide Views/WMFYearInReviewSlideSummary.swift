import SwiftUI

public struct WMFYearInReviewSlideSummary: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFYearInReviewSummaryViewModel
    
    public var body: some View {
        Text("Summary")
    }
}
