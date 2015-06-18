
#import <Foundation/Foundation.h>
#import "PromiseKit.h"

@class MWKSite;
@class WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchFetcher : NSObject

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@property (nonatomic, assign) NSUInteger maxSearchResults;

- (AnyPromise*)searchArticleTitlesForSearchTerm:(NSString*)searchTerm;

- (AnyPromise*)searchFullArticleTextForSearchTerm:(NSString*)searchTerm appendToPreviousResults:(WMFSearchResults*)results;

@end

NS_ASSUME_NONNULL_END