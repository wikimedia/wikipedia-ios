//
//  SDImageCache+PromiseKit.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import PromiseKit

public typealias DiskQueryResult = (cancellable: Cancellable?, promise: Promise<(UIImage, ImageOrigin)>)

extension SDImageCache {
    public func queryDiskCacheForKey(key: String) -> DiskQueryResult {
        let (promise, fulfill, reject) = Promise<(UIImage, ImageOrigin)>.pendingPromise()

        // queryDiskCache will return nil if the image is in memory
        let diskQueryOperation: NSOperation? = self.queryDiskCacheForKey(key, done: { image, cacheType -> Void in
            if image != nil {
                fulfill((image, asImageOrigin(cacheType)))
            } else {
                reject(WMFImageControllerError.DataNotFound)
            }
        })

        if let diskQueryOperation = diskQueryOperation {
            // make sure promise is rejected if the operation is cancelled
            self.KVOController.observe(diskQueryOperation,
                keyPath: "isCancelled",
                options: NSKeyValueObservingOptions.New)
                { _, _, change in
                    let value = change[NSKeyValueChangeNewKey] as! NSNumber
                    if value.boolValue {
                        reject(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                    }
            }

            // tear down observation when operation finishes
            self.KVOController.observe(diskQueryOperation,
                keyPath: "isFinished",
                options: NSKeyValueObservingOptions())
                { [weak self] _, object, _ in
                    self?.KVOController.unobserve(object)
            }
        }

        return (diskQueryOperation, promise)
    }
}
