import Foundation

public struct WKMediaWikiError: Codable, Error {
    let code: String
    let html: String
}
