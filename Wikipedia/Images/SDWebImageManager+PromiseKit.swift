//
//  SDWebImageManager+PromiseKit.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import PromiseKit

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

// FIXME: Can't extend the SDWebImageOperation protocol or cast the return value, so we wrap it.
class SDWebImageOperationWrapper: NSObject, Cancellable {
    weak var operation: SDWebImageOperation?
    required init(operation: SDWebImageOperation) {
        super.init()
        self.operation = operation
        // keep wrapper around as long as operation is around
        objc_setAssociatedObject(operation,
                                 "SDWebImageOperationWrapper",
                                 self,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func cancel() -> Void {
        operation?.cancel()
    }
}

extension SDWebImageManager {
    func promisedImageWithURL(URL: NSURL, options: SDWebImageOptions) -> (Cancellable, Promise<WMFImageDownload>) {
        let (promise, fulfill, reject) = Promise<WMFImageDownload>.pendingPromise()

        let promiseCompatibleOptions: SDWebImageOptions = [options, SDWebImageOptions.ReportCancellationAsError]

        let webImageOperation = self.downloadImageWithURL(URL, options: promiseCompatibleOptions, progress: nil)
        { img, err, cacheType, finished, imageURL in
                if finished && err == nil {
                    fulfill(WMFImageDownload(url: URL, image: img, origin: asImageOrigin(cacheType).rawValue))
                } else {
                    reject(err)
                }
        }

        return (SDWebImageOperationWrapper(operation: webImageOperation), promise)
    }
}
