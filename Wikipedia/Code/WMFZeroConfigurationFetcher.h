@import Foundation;
#import "WMFBlockDefinitions.h"

@interface WMFZeroConfigurationFetcher : NSObject

- (void)fetchZeroConfigurationForSiteURL:(NSURL *)siteURL failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

- (void)cancelAllFetches;

@end
