
#import <Foundation/Foundation.h>

@class MWKArticle;

typedef NS_ENUM (NSUInteger, WMFUserActivityType){
    WMFUserActivityTypeExplore,
    WMFUserActivityTypeSavedPages,
    WMFUserActivityTypeHistory,
    WMFUserActivityTypeSearch,
    WMFUserActivityTypeSearchResults,
    WMFUserActivityTypeArticle,
    WMFUserActivityTypeSettings
};

@interface NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity*)activity;

+ (instancetype)wmf_exploreViewActivity;
+ (instancetype)wmf_savedPagesViewActivity;
+ (instancetype)wmf_recentViewActivity;

+ (instancetype)wmf_searchViewActivity;
+ (instancetype)wmf_searchResultsActivityWithSearchTerm:(NSString*)searchTerm;

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle*)article;

+ (instancetype)wmf_settingsViewActivity;


- (WMFUserActivityType)wmf_type;

- (NSString*)wmf_searchTerm;

@end
