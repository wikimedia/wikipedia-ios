#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadTitleFetcher : NSObject

- (AnyPromise *)fetchMostReadTitlesForSiteURL:(NSURL *)siteURL date:(NSDate *)date;

- (void)fetchPageviewsForURL:(NSURL *)titleURL startDate:(NSDate *)startDate endDate:(NSDate *)endDate failure:(WMFErrorHandler)failure success:(WMFArrayOfNumbersHandler)success;

@end

NS_ASSUME_NONNULL_END
