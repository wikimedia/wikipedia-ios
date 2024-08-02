import Foundation

final public class WMFPaymentSubmissionResponse: Codable {
    public class Response: Codable {
        let status: String
        let errorMessage: String?
        let orderID: String?
        
        enum CodingKeys: String, CodingKey {
            case status = "status"
            case errorMessage = "error_message"
            case orderID = "order_id"
        }
    }
    
    let response: Response
}
