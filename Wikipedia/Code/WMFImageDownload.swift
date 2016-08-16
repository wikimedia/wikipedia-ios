//
//  WMFImageDownload.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

public enum ImageOrigin: Int {
    case network = 0
    case disk = 1
    case memory = 2
    case none = 3
    
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
        case .network:
            return UIColor.redColor()
        case .disk:
            return UIColor.yellowColor()
        case .memory:
            return UIColor.greenColor()
        case .none:
            return UIColor.blackColor()
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
