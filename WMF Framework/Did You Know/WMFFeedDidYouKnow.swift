import Foundation

@objc public class WMFFeedDidYouKnow: NSObject, Decodable {
    @objc public let html: String
    @objc public let text: String
    
    @objc public init(html: String, text: String) {
        self.html = html
        self.text = text
        super.init()
    }
}
