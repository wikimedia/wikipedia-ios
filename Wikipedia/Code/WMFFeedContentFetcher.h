
#import <Foundation/Foundation.h>

@class WMFFeedDayResponse;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentFetcher : NSObject

- (void)fetchFeedContentForURL:(NSURL *)siteURL date:(NSDate *)date failure:(WMFErrorHandler)failure success:(void (^) (WMFFeedDayResponse* feedDay))success;

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFArrayOfNumbersHandler)success;

@end

NS_ASSUME_NONNULL_END
