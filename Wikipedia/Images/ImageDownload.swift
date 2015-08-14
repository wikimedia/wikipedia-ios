//
//  ImageDownload.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

public enum ImageOrigin: String {
    case Network = "Network"
    case Disk = "Disk"
    case Memory = "Memory"
}

extension ImageOrigin: DebugPrintable {
    public var debugDescription: String {
        return rawValue
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
        }
    }
}

public protocol ImageOriginConvertible {
    func asImageOrigin() -> ImageOrigin
}

public func asImageOrigin<T: ImageOriginConvertible>(c: T) -> ImageOrigin { return c.asImageOrigin() }

public struct ImageDownload {
    public var url: NSURL
    public var image: UIImage
    public var origin: ImageOrigin
    public init(url: NSURL, image: UIImage, origin: ImageOrigin) {
        self.url = url
        self.image = image
        self.origin = origin
    }
}
