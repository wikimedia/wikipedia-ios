//
//  WMFImageController+Testing.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import Wikipedia
import SDWebImage

extension WMFImageController {
    public class func temporaryController(downloader: SDWebImageDownloader = SDWebImageDownloader()) -> WMFImageController {
        let cache = SDImageCache(namespace: "temp", inDirectory: WMFRandomTemporaryPath())
        return WMFImageController(manager: SDWebImageManager(downloader: downloader, cache: cache),
                                  namespace: "temp")
    }
}
