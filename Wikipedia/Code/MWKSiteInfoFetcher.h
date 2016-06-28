
@import Foundation;

@class MWKSiteInfo;
@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSiteInfoFetcher : NSObject

- (AnyPromise*)fetchSiteInfoForDomainURL:(NSURL*)domainURL;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
