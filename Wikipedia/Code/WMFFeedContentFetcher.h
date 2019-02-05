@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFLegacyFetcher.h>
@class WMFFeedDayResponse;
@class WMFConfiguration;

typedef void (^WMFPageViewsHandler)(NSDictionary<NSDate *, NSNumber *> *_Nonnull results);

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentFetcher : WMFLegacyFetcher

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success;

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFPageViewsHandler)success;

+ (NSURL *)feedContentURLForSiteURL:(NSURL *)siteURL onDate:(NSDate *)date configuration:(WMFConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
