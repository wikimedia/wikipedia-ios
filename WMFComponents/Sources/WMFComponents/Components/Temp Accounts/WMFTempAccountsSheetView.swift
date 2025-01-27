import SwiftUI
import WMFData

public struct WMFTempAccountsSheetView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTempAccountsSheetViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFTempAccountsSheetViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Image(viewModel.image)
        Text(viewModel.title)
            .font(Font(WMFFont.for(.boldTitle1)))
        Text(viewModel.subtitle)
            .font(Font(WMFFont.for(.boldTitle1)))
    }
}
