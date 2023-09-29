import Foundation

final public class WKPaymentSubmissionResponse: Codable {
    public class Response: Codable {
        let status: String
        let errorMessage: String?
        
        enum CodingKeys: String, CodingKey {
            case status = "status"
            case errorMessage = "error_message"
        }
    }
    
    let response: Response
}
