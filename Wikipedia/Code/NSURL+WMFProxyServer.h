NS_ASSUME_NONNULL_BEGIN

/**
 * Image tag src urls are modified to point to the localhost proxy web server so we can intercept image requests.
 * WKWebView requests are out of process so other methods - NSURLProtocol etc - do not work.
 *
 * For example, the following image url:
 *      //upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 * ...is rewritten to the following format:
 *      http://localhost:58454/7F296C71-1C76-45E5-B5C7-B29643E694AE/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 * Note that the original image url is added as the value for the "originalSrc" query parameter.
 *
 * WMFProxyImageOriginalSrcKey controls the "originalSrc" string in the example above.
 *
 * WMFProxyImageBasePath controls the "imageProxy" string in the example above.
 **/

extern NSString *const WMFProxyImageOriginalSrcKey;
extern NSString *const WMFProxyImageBasePath;
extern NSString *const WMFProxyFileBasePath;
extern NSString *const WMFProxyAPIBasePath;

@interface NSURL (WMFProxyServer)

/**
 * Image proxy urls will have an WMFProxyImageOriginalSrcKey key.
 *
 * @return  Returns the original non-proxy src url. Returns nil if no WMFProxyImageOriginalSrcKey value is found in the underlying NSURL.
 **/
- (nullable NSURL *)wmf_imageProxyOriginalSrcURL;

/**
 * Adds a WMFProxyImageOriginalSrcKey key to the underlying NSURL set to the value passed to the WMFProxyImageOriginalSrcKey parameter.
 *
 * @return  Returns image proxy url.
 **/
- (NSURL *)wmf_imageProxyURLWithOriginalSrc:(NSString *)originalSrc;

@end

NS_ASSUME_NONNULL_END
