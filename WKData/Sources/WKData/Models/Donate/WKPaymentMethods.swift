import Foundation

public struct WKPaymentMethods: Codable {
    
    struct Response: Codable {
        
        struct PaymentMethod: Codable {
            
            public let brands: [String]
            public let name: String
            public let type: String
        }

        let paymentMethods: [PaymentMethod]
    }
    
    private let response: Response
    public var applePayPaymentNetworks: [String] {
        let brands = self.response.paymentMethods.first { $0.type == "applepay" }?.brands ?? []
        
        // Note: This translates brand-style wording to PKPaymentRequest wording
        // TODO: Is there a way around this?
        let paymentNetworks = brands.compactMap { brand in
            switch brand {
            case "amex": return "AmEx"
            case "discover": return "Discover"
            case "maestro": return "Maestro"
            case "mc": return "MasterCard"
            case "visa": return "Visa"
            default: return nil
            }
        }
        
        return paymentNetworks
    }
}
