#import <Foundation/Foundation.h>

@interface WMFZeroConfigurationFetcher : NSObject

- (AnyPromise *)fetchZeroConfigurationForSiteURL:(NSURL *)siteURL;

- (void)cancelAllFetches;

@end
