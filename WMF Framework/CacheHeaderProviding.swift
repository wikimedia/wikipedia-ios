
import Foundation

public protocol CacheHeaderProviding: class {
    func requestHeader(urlRequest: URLRequest) -> [String: String]
}
