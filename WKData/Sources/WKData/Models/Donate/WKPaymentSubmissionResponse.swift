import Foundation

final public class WKPaymentSubmissionResponse: Codable {
    public class Response: Codable {
        let status: String
        let gatewayTransactionID: String?
        let orderID: String?
    }
    
    let response: Response
}
