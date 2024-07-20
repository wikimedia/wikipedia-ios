import Foundation
import SwiftUI
import Combine
import WKData

struct WKDeveloperSettingsView: View {
    
    let viewModel: WKDeveloperSettingsViewModel
    
    var body: some View {
            WKFormView(viewModel: viewModel.formViewModel)
    }
}
