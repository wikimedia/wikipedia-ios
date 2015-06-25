//
//  SDImageCache+PromiseKit.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension SDImageCache {
    public func queryDiskCacheForKey(key: String) -> CancellablePromise<(UIImage, ImageOrigin)> {
        let (promise, fulfill, reject) = CancellablePromise<(UIImage, ImageOrigin)>.defer()

        let diskQueryOperation = self.queryDiskCacheForKey(key, done: { image, cacheType -> Void in
            if image != nil {
                fulfill((image, asImageOrigin(cacheType)))
            } else {
                reject(WMFImageControllerErrorCode.DataNotFound.error)
            }
        })

        // cancel the underlying operation if the promise is cancelled
        promise.catch(policy: CatchPolicy.AllErrors) { error in
            if error.cancelled {
                diskQueryOperation.cancel()
            }
        }

        return promise
    }
}
