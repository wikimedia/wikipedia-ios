#import <Foundation/Foundation.h>

@interface UIViewController (WMFOpenExternalLinkDelegate)

/**
 *  Open an external URL.
 *  In iOS 9, this uses Safari since we get the nice bread crumb.
 *  In iOS 8 we use aninternal browser so they dont'y leave the app
 *
 *  @param url The url to open
 */
- (void)wmf_openExternalUrl:(NSURL *)url;

/**
 *  Open an external URL and specifiy whether or not safari should be used
 *
 *  @param url       The url to use
 *  @param useSafari If YES, then safari will always be used
 */
- (void)wmf_openExternalUrl:(NSURL *)url useSafari:(BOOL)useSafari;

@end