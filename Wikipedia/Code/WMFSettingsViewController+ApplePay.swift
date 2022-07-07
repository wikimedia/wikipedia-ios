import Foundation
import SwiftUI
import PassKit

@objc extension WMFSettingsViewController {
    @objc func showApplePay() {
        let contentView = ApplePayContentView()
        let hostingController = CustomUIHostingController(rootView: contentView)
        hostingController.title = WMFLocalizedString("apple-pay-title", value: "Donate", comment: "Title of the Apple Pay donation screen")
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
