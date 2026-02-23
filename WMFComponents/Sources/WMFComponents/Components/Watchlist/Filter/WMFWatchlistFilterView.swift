import SwiftUI

struct WMFWatchlistFilterView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    @ObservedObject var viewModel: WMFWatchlistFilterViewModel
    
    var body: some View {
        WMFFormView(viewModel: viewModel.formViewModel)
    }
}
