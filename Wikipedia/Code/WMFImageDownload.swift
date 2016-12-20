import Foundation
import SDWebImage

public enum ImageOrigin: Int {
    case network = 0
    case disk = 1
    case memory = 2
    case none = 3
    
    public init(sdOrigin: SDImageCacheType) {
        switch sdOrigin {
        case .disk:
            self = .disk
        case .memory:
            self = .memory
        case .none:
            fallthrough
        default:
            self = .none
        }
    }
}

extension ImageOrigin {
    public var debugColor: UIColor {
        switch self {
        case .network:
            return UIColor.red
        case .disk:
            return UIColor.yellow
        case .memory:
            return UIColor.green
        case .none:
            return UIColor.black
        }
    }
}

public protocol ImageOriginConvertible {
    func asImageOrigin() -> ImageOrigin
}


public func asImageOrigin<T: ImageOriginConvertible>(_ c: T) -> ImageOrigin { return c.asImageOrigin() }

open class WMFImageDownload: NSObject {
    // Exposing enums as string constants for ObjC compatibility
    open static let imageOriginNetwork = ImageOrigin.network.rawValue
    open static let imageOriginDisk = ImageOrigin.disk.rawValue
    open static let imageOriginMemory = ImageOrigin.memory.rawValue

    open var url: URL
    open var image: UIImage
    open var origin: ImageOrigin
    
    
    public init(url: URL, image: UIImage, origin: ImageOrigin) {
        self.url = url
        self.image = image
        self.origin = origin
    }
    
    
    public init(url: URL, image: UIImage, originRawValue: Int) {
        self.url = url
        self.image = image
        self.origin = ImageOrigin(rawValue: originRawValue)!
    }
}
