import Foundation
import SwiftUI

@objc extension WMFSettingsViewController {
    @objc func showApplePay() {
        let contentView = ApplePayContentView()
        let hostingController = ScrollingSwiftUIViewController(contentView: contentView, title: WMFLocalizedString("apple-pay-title", value: "Donate", comment: "Title of the Apple Pay donation screen"), respondsToTextfieldEdits: true, isBarHidingEnabled: false)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
