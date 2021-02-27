import Foundation

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
    @objc open var staticImage: UIImage
    @objc open var animatedImage: FLAnimatedImage?
    @objc public init(staticImage: UIImage, animatedImage: FLAnimatedImage?) {
        self.staticImage = staticImage
        self.animatedImage = animatedImage
    }
}

@objc(WMFImageDownload) public class ImageDownload: NSObject {
    // Exposing enums as string constants for ObjC compatibility
    @objc public static let imageOriginNetwork = ImageOrigin.network.rawValue
    @objc public static let imageOriginDisk = ImageOrigin.disk.rawValue
    @objc public static let imageOriginMemory = ImageOrigin.memory.rawValue
    @objc public static let imageOriginUnknown = ImageOrigin.unknown.rawValue
    
    @objc open var url: URL
    @objc open var image: Image
    open var origin: ImageOrigin
    
    @objc open var originRawValue: Int {
        return origin.rawValue
    }
    
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
