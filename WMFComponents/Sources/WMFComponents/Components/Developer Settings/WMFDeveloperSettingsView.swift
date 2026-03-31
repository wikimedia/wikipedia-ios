import Foundation
import SwiftUI
import Combine
import WMFData

struct WMFDeveloperSettingsView: View {
    
    let viewModel: WMFDeveloperSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            WMFFormView(viewModel: viewModel.formViewModel)
            Button("Reset Reading Challenge State") {
                viewModel.resetReadingChallengeState()
            }
            .padding()
            .foregroundColor(.red)
        }
    }
}
