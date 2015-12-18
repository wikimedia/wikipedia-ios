
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFTitlesSearchFetcher : NSObject

- (AnyPromise*)fetchSearchResultsForTitles:(NSArray<MWKTitle*>*)titles site:(MWKSite*)site;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
