@import Foundation;

@class MWKSiteInfo;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSiteInfoFetcher : NSObject

- (AnyPromise *)fetchSiteInfoForSiteURL:(NSURL *)siteURL;

@property(nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
