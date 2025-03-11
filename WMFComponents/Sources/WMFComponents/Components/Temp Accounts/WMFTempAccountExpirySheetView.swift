import SwiftUI
import WMFData

public struct WMFTempAccountExpirySheetView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var body: some View {
        Text("")
    }
    
}
