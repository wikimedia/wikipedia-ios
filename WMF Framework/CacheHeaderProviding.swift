
import Foundation

protocol CacheHeaderProviding: class {
    func requestHeader(url: URL, forceCache: Bool) -> [String: String]
}
