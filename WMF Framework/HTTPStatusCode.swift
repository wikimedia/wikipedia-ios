import Foundation

public struct HTTPStatusCode {
    public static func isSuccessful(_ statusCode: Int) -> Bool {
        return statusCode >= 200 && statusCode <= 299
    }
}
