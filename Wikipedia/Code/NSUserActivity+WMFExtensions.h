#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFUserActivityType) {
    WMFUserActivityTypeExplore,
    WMFUserActivityTypePlaces,
    WMFUserActivityTypeSavedPages,
    WMFUserActivityTypeSearch,
    WMFUserActivityTypeSearchResults,
    WMFUserActivityTypeSettings,
    WMFUserActivityTypeAppearanceSettings,
    WMFUserActivityTypeContent,
    WMFUserActivityTypeLink,
    WMFUserActivityTypeActivity,
    WMFUserActivityTypeRandom
};

extern NSString *const WMFNavigateToActivityNotification;

// Keys used in a Places activity's `userInfo` when the activity carries an explicit
// map location supplied by the calling app, for example via
// `wikipedia://places?latitude=52.3547&longitude=4.8339&name=Amsterdam`.
//
// When these keys are present the Places tab centers on the supplied coordinate
// instead of falling back to the device's current location.
extern NSString *const WMFPlacesActivityLatitudeKey;
extern NSString *const WMFPlacesActivityLongitudeKey;
extern NSString *const WMFPlacesActivityLocationNameKey;

@interface NSUserActivity (WMFExtensions)

+ (void)wmf_navigateToActivity:(NSUserActivity *)activity;
+ (void)wmf_makeActivityActive:(NSUserActivity *)activity;

+ (instancetype)wmf_contentActivityWithURL:(NSURL *)url;

+ (instancetype)wmf_exploreViewActivity;
+ (instancetype)wmf_savedPagesViewActivity;
+ (instancetype)wmf_activityTabActivity;

+ (instancetype)wmf_searchViewActivity;
+ (instancetype)wmf_searchResultsActivitySearchSiteURL:(NSURL *)url searchTerm:(NSString *)searchTerm;

// Creates a Places activity that asks the Places tab to center its map on an explicit
// coordinate rather than on the device's current location.
// @param latitude Latitude in degrees.
// @param longitude Longitude in degrees.
// @param name Optional human readable name for the location, shown in the search bar.
+ (instancetype)wmf_placesActivityWithLatitude:(double)latitude longitude:(double)longitude name:(nullable NSString *)name;

/// Builds a `wikipedia://places?latitude=…&longitude=…&name=…` URL. Useful for other apps,
/// widgets and tests that need to deep link into the Places tab at a specific location.
+ (NSURL *)wmf_placesURLWithLatitude:(double)latitude longitude:(double)longitude name:(nullable NSString *)name;

+ (instancetype)wmf_settingsViewActivity;
+ (instancetype)wmf_appearanceSettingsActivity;
+ (instancetype)wmf_languageSettingsActivity;

+ (nullable instancetype)wmf_activityForWikipediaScheme:(NSURL *)url;

+ (nullable instancetype)wmf_activityForURL:(NSURL *)url;

- (WMFUserActivityType)wmf_type;

- (nullable NSString *)wmf_searchTerm;

- (nullable NSURL *)wmf_linkURL;

- (NSURL *)wmf_contentURL;

+ (NSURL *)wmf_baseURLForActivityOfType:(WMFUserActivityType)type;

+ (NSURL *)wmf_URLForActivityOfType:(WMFUserActivityType)type withArticleURL:(NSURL *)articleURL;

@end
NS_ASSUME_NONNULL_END
