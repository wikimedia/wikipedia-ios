#import <Foundation/Foundation.h>
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFLegacyFetcher.h>

@class WMFFeedOnThisDayEvent;

@interface WMFOnThisDayEventsFetcher : WMFLegacyFetcher

+ (BOOL)isOnThisDaySupportedByLanguage:(NSString *)languageCode NS_SWIFT_NAME(isOnThisDaySupported(by:));
- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success;

@end
