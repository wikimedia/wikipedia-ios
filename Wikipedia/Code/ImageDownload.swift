import Foundation
import FLAnimatedImage

public enum ImageOrigin: Int {
    case network = 0
    case disk = 1
    case memory = 2
    case unknown = 3
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
        case .unknown:
            return UIColor.black
        }
    }
}

public protocol ImageOriginConvertible {
    func asImageOrigin() -> ImageOrigin
}


public func asImageOrigin<T: ImageOriginConvertible>(_ c: T) -> ImageOrigin { return c.asImageOrigin() }

@objc(WMFImage) public class Image: NSObject {
    open var staticImage: UIImage
    open var animatedImage: FLAnimatedImage?
    public init(staticImage: UIImage, animatedImage: FLAnimatedImage?) {
        self.staticImage = staticImage
        self.animatedImage = animatedImage
    }
}

@objc(WMFImageDownload) public class ImageDownload: NSObject {
    // Exposing enums as string constants for ObjC compatibility
    open static let imageOriginNetwork = ImageOrigin.network.rawValue
    open static let imageOriginDisk = ImageOrigin.disk.rawValue
    open static let imageOriginMemory = ImageOrigin.memory.rawValue
    open static let imageOriginUnknown = ImageOrigin.unknown.rawValue
    
    open var url: URL
    open var image: Image
    open var origin: ImageOrigin
    
    public init(url: URL, image: Image, origin: ImageOrigin) {
        self.url = url
        self.image = image
        self.origin = origin
    }

    public init(url: URL, image: Image, originRawValue: Int) {
        self.url = url
        self.image = image
        self.origin = ImageOrigin(rawValue: originRawValue)!
    }
}
