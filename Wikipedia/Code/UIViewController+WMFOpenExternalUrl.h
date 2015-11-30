#import <Foundation/Foundation.h>

@interface UIViewController (WMFOpenExternalLinkDelegate)

- (void)wmf_openExternalUrl:(NSURL*)url;

@end