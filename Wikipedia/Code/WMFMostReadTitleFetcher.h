#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadTitleFetcher : NSObject

- (AnyPromise *)fetchMostReadTitlesForSiteURL:(NSURL *)siteURL
                                         date:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
