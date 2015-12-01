
#import <Foundation/Foundation.h>

@class MWKSite;
@class WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const WMFMaxSearchResultLimit;

@interface WMFSearchFetcher : NSObject

- (AnyPromise*)fetchArticlesForSearchTerm:(NSString*)searchTerm
                                     site:(MWKSite*)site
                              resultLimit:(NSUInteger)resultLimit;

- (AnyPromise*)fetchArticlesForSearchTerm:(NSString*)searchTerm
                                     site:(MWKSite*)site
                              resultLimit:(NSUInteger)resultLimit
                           fullTextSearch:(BOOL)fullTextSearch
                  appendToPreviousResults:(nullable WMFSearchResults*)results;

@end

NS_ASSUME_NONNULL_END