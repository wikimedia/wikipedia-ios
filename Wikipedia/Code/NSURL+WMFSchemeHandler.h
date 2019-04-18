@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * URLs are modified to point to the app scheme handler so we can intercept requests.
 *
 *
 * For example, the following image url:
 *      //upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 * ...is rewritten to the following format:
 *      wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Backbeat_chop.png/300px-Backbeat_chop.png
 *
 **/

extern NSString *const WMFURLSchemeHandlerScheme;

@interface NSURL (WMFSchemeHandler)

/**
 * App scheme urls will have an WMFURLSchemeHandlerScheme scheme.
 *
 * @return  Returns the original non-app scheme src url. Returns nil if unable to convert.
 **/
- (nullable NSURL *)wmf_originalURLFromAppSchemeURL;

/**
 * Changes the scheme to WMFURLSchemeHandlerScheme.
 *
 * @return  Returns app scheme url.
 **/
+ (NSURL *)wmf_appSchemeURLForURLString:(NSString *)URLString;

@end

NS_ASSUME_NONNULL_END
