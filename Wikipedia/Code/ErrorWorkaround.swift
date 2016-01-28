//
//  ErrorWorkaround.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 1/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

import Foundation

public func ==(foundationError: NSError, swiftError: ErrorType) -> Bool {
    let castedError = swiftError as NSError
    return foundationError.domain == castedError.domain && foundationError.code == castedError.code
}

// need to declare the "flipped" version of NSError == ErrorType
public func ==(swiftError: ErrorType, foundationError: NSError) -> Bool {
    return foundationError == swiftError
}

#if DEBUG
extension WMFImageController {
    public class func _castedImageError() -> NSError {
        return WMFImageControllerError.InvalidOrEmptyURL as NSError
    }
}
#endif
