#import <Foundation/Foundation.h>

@class WMFFeedDayResponse;

typedef void (^WMFPageViewsHandler)(NSDictionary<NSDate *, NSNumber *> *_Nonnull results);

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentFetcher : NSObject

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success;

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(WMFFeedDayResponse *feedDay))success;

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFPageViewsHandler)success;


@end

NS_ASSUME_NONNULL_END
