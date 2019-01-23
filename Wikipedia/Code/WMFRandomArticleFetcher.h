@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFFetcher.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : WMFFetcher

- (void)fetchRandomArticleWithSiteURL:(NSURL *)siteURL completion:(void (^)(NSError *_Nullable error, MWKSearchResult *_Nullable result))completion;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
