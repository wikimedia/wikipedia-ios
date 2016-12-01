import Foundation
import WebImage

public enum ImageOrigin: Int {
    case Network = 0
    case Disk = 1
    case Memory = 2
    case None = 3
    
    public init(sdOrigin: SDImageCacheType) {
        switch sdOrigin {
        case .Disk:
            self = .Disk
        case .Memory:
            self = .Memory
        case .None:
            fallthrough
        default:
            self = .None
        }
    }
}

extension ImageOrigin {
    public var debugColor: UIColor {
        switch self {
        case .Network:
            return UIColor.redColor()
        case .Disk:
            return UIColor.yellowColor()
        case .Memory:
            return UIColor.greenColor()
        case .None:
            return UIColor.blackColor()
        }
    }
}

public protocol ImageOriginConvertible {
    func asImageOrigin() -> ImageOrigin
}


public func asImageOrigin<T: ImageOriginConvertible>(c: T) -> ImageOrigin { return c.asImageOrigin() }

public class WMFImageDownload: NSObject {
    // Exposing enums as string constants for ObjC compatibility
    public static let imageOriginNetwork = ImageOrigin.Network.rawValue
    public static let imageOriginDisk = ImageOrigin.Disk.rawValue
    public static let imageOriginMemory = ImageOrigin.Memory.rawValue

    public var url: NSURL
    public var image: UIImage
    public var origin: ImageOrigin
    
    
    public init(url: NSURL, image: UIImage, origin: ImageOrigin) {
        self.url = url
        self.image = image
        self.origin = origin
    }
    
    
    public init(url: NSURL, image: UIImage, originRawValue: Int) {
        self.url = url
        self.image = image
        self.origin = ImageOrigin(rawValue: originRawValue)!
    }
}
