import SwiftUI

public struct WMFYearInReviewSlideHighlights: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFYearInReviewHighlightsViewModel
    
    public var body: some View {
        Text("Summary")
    }
}
