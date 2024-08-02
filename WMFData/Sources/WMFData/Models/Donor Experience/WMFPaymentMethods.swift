import Foundation
import PassKit

public struct WMFPaymentMethods: Codable {
    
    struct Response: Codable {
        
        struct PaymentMethod: Codable {
            
            public let brands: [String]?
            public let name: String
            public let type: String
        }

        let paymentMethods: [PaymentMethod]
    }
    
    private let response: Response
    var cachedDate: Date?
    
    public var applePayPaymentNetworks: [PKPaymentNetwork] {
        let brands = self.response.paymentMethods.first { $0.type == "applepay" }?.brands ?? []
        
        let paymentNetworks = PKPaymentRequest.availableNetworks()
        let brandsSet = Set(brands)

        return paymentNetworks.filter { brandsSet.contains($0.brandName) }
    }
}

// Taken from https://github.com/Adyen/adyen-ios/blob/b56be842b3e9ae49798c1cfc527d2f1df334ee80/AdyenComponents/Apple%20Pay/ApplePayConfiguration.swift#L176

private extension PKPaymentNetwork {
    var brandName: String {
        if self == .masterCard { return "mc" }
        if self == .cartesBancaires { return "cartebancaire" }
        return self.rawValue.lowercased()
    }
}
