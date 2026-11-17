import Foundation

extension Bundle {
    @objc public static let wmf: Bundle = Bundle(for: Configuration.self)
    
    @objc(wmf_assetsFolderURL)
    public var assetsFolderURL: URL {
        return url(forResource: "assets", withExtension: nil)!
    }
}
