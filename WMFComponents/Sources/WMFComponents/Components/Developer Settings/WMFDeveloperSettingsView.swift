import Foundation
import SwiftUI
import Combine
import WMFData

struct WMFDeveloperSettingsView: View {
    
    let viewModel: WMFDeveloperSettingsViewModel
    
    var body: some View {
            WMFFormView(viewModel: viewModel.formViewModel)
    }
}
