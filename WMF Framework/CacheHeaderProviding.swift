
import Foundation

protocol CacheHeaderProviding: class {
    func requestHeader(urlRequest: URLRequest) -> [String: String]
}
