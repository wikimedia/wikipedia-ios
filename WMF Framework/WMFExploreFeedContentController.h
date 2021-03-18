#import <WMF/WMFContentGroup+Extensions.h>

@import UIKit;

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFExploreFeedPreferencesGlobalCardsKey;
extern NSString *const WMFExploreFeedContentControllerBusyStateDidChange;
extern NSString *const WMFExploreFeedPreferencesDidChangeNotification;
extern NSString *const WMFExploreFeedPreferencesDidSaveNotification;
extern NSString *const WMFNewExploreFeedPreferencesWereRejectedNotification;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

@interface WMFExploreFeedContentController : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, readonly) NSInteger countOfVisibleContentGroupKinds;

/// Stops all content sources, recreates them from current preferred languages, and starts them
- (void)updateContentSources;

- (void)startContentSources;
- (void)stopContentSources;

- (void)cancelAllFetches;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;
- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;

- (void)performDeduplicatedFetch:(nullable dispatch_block_t)completion;

- (void)updateContentSource:(Class)class force:(BOOL)force completion:(nullable dispatch_block_t)completion;

// Preferences

/**
 Toggles all customizable content groups on or off for a given siteURL.

 @param siteURL A Wikipedia site url for which all customizable content groups will be visible or hidden in the feed.
 @param isOn A flag that indicates whether all customizable content groups should be visible or hidden for a given siteURL in the feed.
 @param updateFeed A flag that indicates whether feed should be updated after Explore feed preferences are updated.
 */
-(void)toggleContentForSiteURL:(NSURL *)siteURL isOn:(BOOL)isOn waitForCallbackFromCoordinator:(BOOL)waitForCallbackFromCoordinator updateFeed:(BOOL)updateFeed;

/**
 Toggles a content group of given kind on or off for all preferred languages.

 @param contentGroupKind The kind of the content group that is about to be toggled on or off in the feed.
 @param isOn A flag indicating whether the group should be visible in the feed or not.
 */
- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn updateFeed:(BOOL)updateFeed;

- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn waitForCallbackFromCoordinator:(BOOL)waitForCallbackFromCoordinator apply:(BOOL)apply updateFeed:(BOOL)updateFeed;

/**
 Toggles a content group of given kind on or off for a given siteURL.

 @param contentGroupKind The kind of the content group that is about to be toggled on or off in the feed.
 @param isOn A flag indicating whether the group should be visible in the feed or not.
 @param siteURL A Wikipedia site url for which a content group of given kind will be visible or hidden in the feed.
 */
- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn forSiteURL:(NSURL *)siteURL updateFeed:(BOOL)updateFeed;

- (void)toggleAllContentGroupKinds:(BOOL)on updateFeed:(BOOL)updateFeed;

/**
 Toggles non-language specific content group kinds (Because you read, Continue reading and Picture of the day)

 @param on A flag indicating whether non-language specific groups should be visible in the feed.
 */
- (void)toggleGlobalContentGroupKinds:(BOOL)on updateFeed:(BOOL)updateFeed;

/**
 Returns a set of language codes representing languages in which a given content group kind is visible in the feed.

 @param contentGroupKind The kind of the content group whose language codes you want to get.
 @return A set of language codes representing languages in which a given content group kind is visible in the feed.
 If a given content group kind is not visible in any languages, the set will be empty.
 */
- (NSArray<NSString *> *_Nonnull)contentLanguageCodesForContentGroupKind:(WMFContentGroupKind)contentGroupKind;

/**
 Returns a flag indicating whether there are any customizable content groups visible in the feed for a given siteURL.
 */
- (BOOL)anyContentGroupsVisibleInTheFeedForSiteURL:(NSURL *)siteURL;

/**
 Returns a set of integers that represent customizable content group kinds.
 */
+ (NSSet<NSNumber *> *)customizableContentGroupKindNumbers;

/**
 Returns a set of integers that represent non-language specific content group kinds.
 */
+ (NSSet<NSNumber *> *)globalContentGroupKindNumbers;

/**
 Indicates whether non-language specific group kinds are visible in the feed.
 */
@property (nonatomic, readonly) BOOL areGlobalContentGroupKindsInFeed;

- (BOOL)isGlobalContentGroupKindInFeed:(WMFContentGroupKind)contentGroupKind;

- (void)saveNewExploreFeedPreferences:(NSDictionary *)newExploreFeedPreferences apply:(BOOL)apply updateFeed:(BOOL)updateFeed;
- (void)rejectNewExploreFeedPreferences;

- (void)dismissCollapsedContentGroups;

#if DEBUG
- (void)debugChaos;
#endif

@end

@interface WMFExploreFeedContentController (LanguageVariantMigration)
/// The expected dictionary uses language codes as the key with the value being the desired language variant code for that language.
- (void)migrateExploreFeedSettingsToLanguageVariants:(NSDictionary<NSString *, NSString *> *)languageMapping inManagedObjectContext:(NSManagedObjectContext *)moc;
@end

NS_ASSUME_NONNULL_END
