//
//  SDWebImageManager+PromiseKit.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension SDImageCacheType: ImageOriginConvertible {
    public func asImageOrigin() -> ImageOrigin {
        switch self {
        case SDImageCacheType.Disk:
            return ImageOrigin.Disk
        case SDImageCacheType.Memory:
            return ImageOrigin.Memory
        case SDImageCacheType.None:
            return ImageOrigin.Network
        }
    }
}

extension SDWebImageManager {
    func promisedImageWithURL(URL: NSURL, options: SDWebImageOptions) -> CancellablePromise<ImageDownload> {
        let (promise, fulfill, reject) = CancellablePromise<ImageDownload>.defer()

        let webImageOperation = self.downloadImageWithURL(URL, options: options, progress: nil)
        { img, err, cacheType, finished, imageURL in
                if finished && err == nil {
                    fulfill(ImageDownload(url: URL, image: img, origin: asImageOrigin(cacheType)))
                } else {
                    reject(err)
                }
        }

        return promise
    }
}
