import SwiftUI
import Foundation
import WMFData

public struct WMFActivityTabCustomizeView: View {
    @State private var viewModel: WMFActivityTabCustomizeViewModel
    
    public init(viewModel: WMFActivityTabCustomizeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Form {
            ForEach(viewModel.toggleMappings.indices, id: \.self) { index in
                Toggle(
                    viewModel.toggleMappings[index].label,
                    isOn: viewModel.toggleMappings[index].binding
                )
            }
        }
    }
}
