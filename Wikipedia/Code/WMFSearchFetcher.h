#import <Foundation/Foundation.h>

@class WMFSearchResults;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const WMFMaxSearchResultLimit;

@interface WMFSearchFetcher : NSObject

- (void)fetchArticlesForSearchTerm:(NSString *)searchTerm
                           siteURL:(NSURL *)siteURL
                       resultLimit:(NSUInteger)resultLimit
                             failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success;


- (void)fetchArticlesForSearchTerm:(NSString *)searchTerm
                                   siteURL:(NSURL *)siteURL
                               resultLimit:(NSUInteger)resultLimit
                            fullTextSearch:(BOOL)fullTextSearch
                   appendToPreviousResults:(nullable WMFSearchResults *)results
                             failure:(WMFErrorHandler)failure
                           success:(WMFSearchResultsHandler)success;

@end

NS_ASSUME_NONNULL_END
