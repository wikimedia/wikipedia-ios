NS_ASSUME_NONNULL_BEGIN
@class MWKArticle;

typedef NS_ENUM(NSUInteger, WMFUserActivityType) {
    WMFUserActivityTypeExplore,
    WMFUserActivityTypeSavedPages,
    WMFUserActivityTypeHistory,
    WMFUserActivityTypeSearch,
    WMFUserActivityTypeSearchResults,
    WMFUserActivityTypeArticle,
    WMFUserActivityTypeSettings,
    WMFUserActivityTypeTopRead,
    WMFUserActivityTypeGenericLink
};

@interface NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity *)activity;

+ (instancetype)wmf_exploreViewActivity;
+ (instancetype)wmf_savedPagesViewActivity;
+ (instancetype)wmf_recentViewActivity;

+ (instancetype)wmf_searchViewActivity;
+ (instancetype)wmf_searchResultsActivitySearchSiteURL:(NSURL *)url searchTerm:(NSString *)searchTerm;

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle *)article;

+ (instancetype)wmf_settingsViewActivity;

+ (instancetype)wmf_activityForWikipediaScheme:(NSURL *)url;

- (WMFUserActivityType)wmf_type;

- (NSString *)wmf_searchTerm;

- (NSURL *)wmf_articleURL;

+ (nullable NSURL *)wmf_URLForActivityOfType:(WMFUserActivityType)type parameters:(nullable NSDictionary *)params;

@end
NS_ASSUME_NONNULL_END
