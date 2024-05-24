import Foundation
import SwiftUI
import PassKit
import UIKit

struct WKApplePayDonateButton: UIViewRepresentable {
    
    struct Configuration {
        let paymentButtonStyle: PKPaymentButtonStyle
    }
    
    let configuration: Configuration

    func makeUIView(context: Context) -> PKPaymentButton {
        return PKPaymentButton(paymentButtonType: .donate, paymentButtonStyle: configuration.paymentButtonStyle)
    }

    func updateUIView(_ uiView: PKPaymentButton, context: UIViewRepresentableContext<WKApplePayDonateButton>) {
        
    }
}
