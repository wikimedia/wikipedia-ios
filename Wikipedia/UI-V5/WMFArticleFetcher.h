
#import <Foundation/Foundation.h>

@class MWKSite;
@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ WMFArticleFetcherProgress)(CGFloat progress);

@interface WMFArticleFetcher : NSObject

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFArticleFetcherProgress)progress;

- (void)cancelCurrentFetch;

@end

NS_ASSUME_NONNULL_END