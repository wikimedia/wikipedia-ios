import Foundation
import Testing
@testable import WMF

/// Mantle decodes every property key, even ones excluded from encoding. With assertions on, a key without allowed secure coding classes
/// or its own decode<Key>WithCoder:modelVersion: crashes when Core Data reads an archived search result, e.g. a recent Places search.
struct MWKSearchResultSecureCodingTests {
    @Test(arguments: [MWKSearchResult.self, MWKLocationSearchResult.self] as [MTLModel.Type])
    func everyPropertyCanBeSecurelyDecoded(modelClass: MTLModel.Type) {
        let allowedClasses = modelClass.allowedSecureCodingClassesByPropertyKey() ?? [:]
        for case let key as String in modelClass.propertyKeys() {
            let decodeSelector = NSSelectorFromString("decode\(key.prefix(1).uppercased())\(key.dropFirst())WithCoder:modelVersion:")
            #expect(allowedClasses[key] != nil || modelClass.instancesRespond(to: decodeSelector), "\(modelClass) cannot securely decode \(key)")
        }
    }
}
