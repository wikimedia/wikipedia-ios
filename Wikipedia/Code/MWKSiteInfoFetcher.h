@import Foundation;
#import <WMF/WMFLegacyFetcher.h>
@class MWKSiteInfo;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSiteInfoFetcher : WMFLegacyFetcher

- (void)fetchSiteInfoForSiteURL:(NSURL *)siteURL completion:(void (^)(MWKSiteInfo *data))completion failure:(void (^)(NSError *error))failure;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
