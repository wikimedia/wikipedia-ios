#import <Foundation/Foundation.h>

@interface WMFZeroMessageFetcher : NSObject

- (AnyPromise *)fetchZeroMessageForSiteURL:(NSURL *)siteURL;

- (void)cancelAllFetches;

@end
