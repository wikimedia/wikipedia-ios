//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFProxyServer)

/**
 * Image proxy urls will have an "originalSrc" key.
 *
 * @return  Returns the original non-proxy src url. Returns nil if no 'originalSrc' value found.
 **/
- (nullable NSURL*)wmf_imageProxyOriginalSrcURL;

@end

NS_ASSUME_NONNULL_END
