@import Foundation;
NS_ASSUME_NONNULL_BEGIN
@class MWKArticle;

typedef NS_ENUM(NSUInteger, WMFUserActivityType) {
    WMFUserActivityTypeExplore,
    WMFUserActivityTypePlaces,
    WMFUserActivityTypeSavedPages,
    WMFUserActivityTypeHistory,
    WMFUserActivityTypeSearch,
    WMFUserActivityTypeSearchResults,
    WMFUserActivityTypeArticle,
    WMFUserActivityTypeSettings,
    WMFUserActivityTypeAppearanceSettings,
    WMFUserActivityTypeContent,
    WMFUserActivityTypeGenericLink,
    WMFUserActivityTypeSpecialPage
};

extern NSString *const WMFNavigateToActivityNotification;

@interface NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity *)activity;

+ (instancetype)wmf_contentActivityWithURL:(NSURL *)url;

+ (instancetype)wmf_exploreViewActivity;
+ (instancetype)wmf_savedPagesViewActivity;
+ (instancetype)wmf_recentViewActivity;

+ (instancetype)wmf_searchViewActivity;
+ (instancetype)wmf_searchResultsActivitySearchSiteURL:(NSURL *)url searchTerm:(NSString *)searchTerm;

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle *)article;

+ (instancetype)wmf_settingsViewActivity;
+ (instancetype)wmf_appearanceSettingsActivity;

+ (instancetype)wmf_specialPageActivityWithURL:(NSURL *)url;

+ (nullable instancetype)wmf_activityForWikipediaScheme:(NSURL *)url;

+ (nullable instancetype)wmf_activityForURL:(NSURL *)url;

- (WMFUserActivityType)wmf_type;

- (nullable NSString *)wmf_searchTerm;

- (nullable NSURL *)wmf_articleURL;

- (NSURL *)wmf_contentURL;

+ (NSURL *)wmf_baseURLForActivityOfType:(WMFUserActivityType)type;

+ (NSURL *)wmf_URLForActivityOfType:(WMFUserActivityType)type withArticleURL:(NSURL *)articleURL;

@end
NS_ASSUME_NONNULL_END
