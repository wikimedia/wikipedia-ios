//
//  WMFImageController+Debug.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

#if DEBUG
// Enable to colorize images based on whether they were loaded from memory, disk, or network.
let APPLY_IMAGE_OVERLAYS = false
#endif

internal extension WMFImageController {
    func maybeApplyDebugTransforms(promise: Promise<ImageDownload>) -> Promise<ImageDownload> {
        #if NDEBUG
            return promise
        #else
            if !APPLY_IMAGE_OVERLAYS {
                return promise
            } else {
                return promise.thenInBackground(applyDebugTransforms)
            }
        #endif
    }

    private func applyDebugTransforms(toDownload download: ImageDownload) -> ImageDownload {
        var transformedDownload = download
        transformedDownload.image = download.image.wmf_imageByDrawingInContext() {
            download.image.wmf_fillCurrentContext()
            // tint
            CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), download.origin.debugColor.CGColor)
            UIRectFillUsingBlendMode(download.image.wmf_frame, kCGBlendModeOverlay)
        }
        return transformedDownload
    }
}
