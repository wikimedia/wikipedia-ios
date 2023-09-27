import Foundation

final public class WKPaymentSubmissionResponse: Codable {
    public class Response: Codable {
        let status: String
        let gatewayTransactionID: String?
        let orderID: String?
    }
    
    let response: Response
}

/// {"response":{"status":"Success","gateway_transaction_id":"PVLSL6JZ4NK2WN82","order_id":"1235.1"}}
