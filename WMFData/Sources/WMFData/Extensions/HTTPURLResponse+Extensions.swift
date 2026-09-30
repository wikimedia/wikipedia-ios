import Foundation

extension HTTPURLResponse {
    var isSuccessStatusCode: Bool {
        return (200..<300).contains(self.statusCode)
    }

    public var isHTTPError: Bool {
        statusCode >= 400
    }
}
