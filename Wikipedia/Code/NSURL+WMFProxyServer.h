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
 * Image proxy urls will have an "originalSrc" key.
 *
 * @return  Returns the original non-proxy src url. Returns nil if no 'originalSrc' value found.
 **/
- (nullable NSURL*)wmf_imageProxyOriginalSrcURL;

@end

NS_ASSUME_NONNULL_END
