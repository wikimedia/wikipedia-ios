@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFFetcher.h>

@class WMFFeedOnThisDayEvent;

@interface WMFOnThisDayEventsFetcher : WMFFetcher

- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success;

@end
