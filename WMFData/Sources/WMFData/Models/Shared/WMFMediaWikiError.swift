import Foundation

public struct WMFMediaWikiError: Codable, Error {
    let code: String
    let html: String
}
