import SwiftUI

struct WMFYearInReviewSlideSummaryShareableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFYearInReviewSummaryViewModel

    var body: some View {
        Text("Shareable summary")
    }

}
