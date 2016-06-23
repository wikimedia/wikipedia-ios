//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

NS_ASSUME_NONNULL_BEGIN

/**
 * When modifying image src urls to point to the localhost proxy, this string is used as the query parameter key for relaying the original image url. For example, in the url "http://localhost:8080?originalSrc=http://someimagepath.jpg" the WMFImageProxyOriginalSrcKey is "originalSrc".
 *
 **/
extern NSString* const WMFImageProxyOriginalSrcKey;

@interface NSURL (WMFProxyServer)

/**
 * Image proxy urls will have an WMFImageProxyOriginalSrcKey key.
 *
 * @return  Returns the original non-proxy src url. Returns nil if no 'originalSrc' value is found in the underlying NSURL.
 **/
- (nullable NSURL*)wmf_imageProxyOriginalSrcURL;

/**
 * Adds a WMFImageProxyOriginalSrcKey key to the underlying NSURL set to the value passed to the 'originalSrc' parameter.
 *
 * @return  Returns image proxy url.
 **/
- (nullable NSURL*)wmf_imageProxyURLWithOriginalSrc:(NSString*)originalSrc;

@end

NS_ASSUME_NONNULL_END
