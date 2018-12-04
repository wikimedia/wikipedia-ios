@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * Image tag src urls are modified to point to the app scheme handler so we can intercept image requests.
 * WKWebView requests are out of process so other methods - NSURLProtocol etc - do not work.
 *
 * For example, the following image url:
 *      //upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 * ...is rewritten to the following format:
 *      wmfapp://host/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 * Note that the original image url is added as the value for the "originalSrc" query parameter.
 *
 * WMFAppSchemeImageOriginalSrcKey controls the "originalSrc" string in the example above.
 *
 * WMFAppSchemeImageBasePath controls the "imageProxy" string in the example above.
 **/

extern NSString *const WMFAppSchemeImageOriginalSrcKey;
extern NSString *const WMFAppSchemeImageBasePath;
extern NSString *const WMFAppSchemeFileBasePath;
extern NSString *const WMFAppSchemeAPIBasePath;

@interface NSURL (WMFSchemeHandler)

/**
 * Image app scheme urls will have an WMFAppSchemeImageOriginalSrcKey key.
 *
 * @return  Returns the original non-app scheme src url. Returns nil if no WMFAppSchemeImageOriginalSrcKey value is found in the underlying NSURL.
 **/
- (nullable NSURL *)wmf_imageAppSchemeOriginalSrcURL;

/**
 * Adds a WMFAppSchemeImageOriginalSrcKey key to the underlying NSURL set to the value passed to the WMFAppSchemeImageOriginalSrcKey parameter.
 *
 * @return  Returns image app scheme url.
 **/
- (NSURL *)wmf_imageAppSchemeURLWithOriginalSrc:(NSString *)originalSrc;

@end

NS_ASSUME_NONNULL_END
