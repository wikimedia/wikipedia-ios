
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreviewFetcher : NSObject

- (AnyPromise*)fetchArticlePreviewResultsForTitles:(NSArray<MWKTitle*>*)titles site:(MWKSite*)site;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
