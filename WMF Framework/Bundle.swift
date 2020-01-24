import Foundation

extension Bundle {
    @objc public static let wmf: Bundle = Bundle(identifier: "org.wikimedia.WMF")!
    
    @objc(wmf_assetsFolderURL)
    public var assetsFolderURL: URL {
        return url(forResource: "assets", withExtension: nil)!
    }
}
