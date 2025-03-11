import SwiftUI

class WMFTempAccountExpirySheetHostingController: UIHostingController<WMFTempAccountExpirySheetView> {
    public init() {
        super.init(rootView: WMFTempAccountExpirySheetView())
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
