#import <Foundation/Foundation.h>

@class WMFRelatedSearchResults;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const WMFMaxRelatedSearchResultLimit;

///
///  @name Fetching Extracts
///

/**
 *  TextExtracts will return HTML truncated as follows (taken from the article on Food Preparation on EN Wikipedia):
 *
   @code
   <p>The following outline is provided as an overview of and a topical guide to food preparation:</p>
   <p><b>Food preparation</b> – preparing food for eating</p>...
   @endcode
 *
 *  Which ends up looking like:
 *
   @code
   The following outline is provided as an overview of and a topical guide to food preparation:
   Food preparation - preparing food for eating
   ...
   @endcode
 *
 *  This poses multiple problems:
 *      - Possibility of double truncation
 *      - Ellipsis appearing on its own line
 *
 *  To circumvent this, it's recommended to request a number of extract characters that will force your
 *  view/label/textview to truncate the string.  For example, adding an extra half or whole line to the number of
 *  characters parameter.
 */

@interface WMFRelatedSearchFetcher : NSObject

/**
 *  Query a site for titles related to a given title.
 *
 *  @param title        The title for which to find related content, as well as the site to pull content from.
 *  @param resultLimit  Maximum number of search results, limited to WMFMaxRelatedSearchResultLimit.
 *
 *  @return A promise which resolves to an instance of @c WMFRelatedSearchResults.
 *
 *  @see Fetching Extracts
 */

- (void)fetchArticlesRelatedArticleWithURL:(NSURL *)URL
                               resultLimit:(NSUInteger)resultLimit
                           completionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                              failureBlock:(void (^)(NSError *error))failure;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
