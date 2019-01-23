@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFLegacyFetcher.h>

@class WMFFeedOnThisDayEvent;

@interface WMFOnThisDayEventsFetcher : WMFLegacyFetcher

- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success;

@end
