@import Foundation;
#import <WMF/WMFBlockDefinitions.h>

@class WMFFeedOnThisDayEvent;

@interface WMFOnThisDayEventsFetcher : NSObject

- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success;

@end
