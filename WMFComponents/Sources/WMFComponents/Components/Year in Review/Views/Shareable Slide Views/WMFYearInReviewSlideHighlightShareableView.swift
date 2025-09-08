import SwiftUI

struct WMFYearInReviewSlideHighlightShareableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFYearInReviewHighlightsViewModel

    var body: some View {
        Text("Shareable summary")
    }

}
