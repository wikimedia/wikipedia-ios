
#import <Foundation/Foundation.h>

@class MWKArticle;

@interface NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity*)activity;

+ (instancetype)wmf_exploreViewActivity;
+ (instancetype)wmf_savedPagesViewActivity;
+ (instancetype)wmf_recentViewActivity;

+ (instancetype)wmf_searchViewActivity;
+ (instancetype)wmf_searchResultsActivityWithSearchTerm:(NSString*)searchTerm;

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle*)article;


@end
