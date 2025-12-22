import SwiftUI

public struct WMFSearchView: View {
    
    @ObservedObject var viewModel: WMFSearchViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFSearchViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Text("Search")
    }
}
