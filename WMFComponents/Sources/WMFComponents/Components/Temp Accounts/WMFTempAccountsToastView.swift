import SwiftUI
import WMFData

public struct WMFTempAccountsToastView: View {
    var viewModel: WMFTempAccountsToastViewModel
    
    public init(viewModel: WMFTempAccountsToastViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            Image("close")
            HStack {
                Image("alert")
                Text("words")
            }
            Button("Read more", action: {
                
            })
        }
    }
}
