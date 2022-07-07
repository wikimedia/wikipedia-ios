import SwiftUI
import PassKit
import UIKit

struct ApplePayDonateButton: UIViewRepresentable {
    
    let needsSetup: Bool
    
    init(needsSetup: Bool = false) {
        print("initing new apple pay button with: \(needsSetup)")
        self.needsSetup = needsSetup
    }

    func makeUIView(context: Context) -> PKPaymentButton {
        print("making new UI view")
        let paymentButtonType: PKPaymentButtonType = needsSetup ? .setUp : .donate
        return PKPaymentButton(paymentButtonType: paymentButtonType, paymentButtonStyle: .black)
    }

    func updateUIView(_ uiView: PKPaymentButton, context: UIViewRepresentableContext<ApplePayDonateButton>) {
        print("updateUIView")
    }
}
