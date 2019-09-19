@import UIKit.UIViewController;

@interface UIViewController (WMFOpenExternalLinkDelegate)

/**
 *  Open an external URL.
 *  Uses Safari.
 *
 *  @param url The url to open
 */
- (void)wmf_openExternalUrl:(nullable NSURL *)url;

/**
 *  Open an external URL and specifiy whether or not Safari should be used
 *
 *  @param url       The url to use
 *  @param useSafari If YES, then safari will always be used
 */
- (void)wmf_openExternalUrl:(nullable NSURL *)url useSafari:(BOOL)useSafari;

@end
