import SwiftUI

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var viewModel: WMFActivityTabViewModel
    
    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            Text(viewModel.username)
            Text(viewModel.localizedStrings.totalHoursMinutesRead)
            Text(viewModel.localizedStrings.onWikipediaiOS)
        }
    }
}

