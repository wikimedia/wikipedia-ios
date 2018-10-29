#import "WMFContentGroup+Extensions.h"

@import UIKit;

@class MWKDataStore;

extern NSString *_Nonnull const WMFExploreFeedPreferencesGlobalCardsKey;
extern NSString *_Nonnull const WMFExploreFeedContentControllerBusyStateDidChange;
extern NSString *_Nonnull const WMFExploreFeedPreferencesDidChangeNotification;
extern NSString *_Nonnull const WMFExploreFeedPreferencesDidSaveNotification;
extern NSString *_Nonnull const WMFNewExploreFeedPreferencesWereRejectedNotification;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

@interface WMFExploreFeedContentController : NSObject

@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, weak, nullable) MWKDataStore *dataStore;
@property (nonatomic, copy, nullable) NSArray<NSURL *> *siteURLs;
@property (nonatomic, readonly) NSInteger countOfVisibleContentGroupKinds;

- (void)startContentSources;
- (void)stopContentSources;

- (void)cancelAllFetches;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;
- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;

- (void)updateNearbyForce:(BOOL)force completion:(nullable dispatch_block_t)completion;

// Preferences

/**
 Toggles all customizable content groups on or off for a given siteURL.

 @param siteURL A Wikipedia site url for which all customizable content groups will be visible or hidden in the feed.
 @param isOn A flag that indicates whether all customizable content groups should be visible or hidden for a given siteURL in the feed.
 @param updateFeed A flag that indicates whether feed should be updated after Explore feed preferences are updated.
 */
-(void)toggleContentForSiteURL:(nonnull NSURL *)siteURL isOn:(BOOL)isOn waitForCallbackFromCoordinator:(BOOL)waitForCallbackFromCoordinator updateFeed:(BOOL)updateFeed;

/**
 Toggles a content group of given kind on or off for all preferred languages.

 @param contentGroupKind The kind of the content group that is about to be toggled on or off in the feed.
 @param isOn A flag indicating whether the group should be visible in the feed or not.
 */
- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn;

- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn waitForCallbackFromCoordinator:(BOOL)waitForCallbackFromCoordinator apply:(BOOL)apply updateFeed:(BOOL)updateFeed completion:(nullable dispatch_block_t)completion;

/**
 Toggles a content group of given kind on or off for a given siteURL.

 @param contentGroupKind The kind of the content group that is about to be toggled on or off in the feed.
 @param isOn A flag indicating whether the group should be visible in the feed or not.
 @param siteURL A Wikipedia site url for which a content group of given kind will be visible or hidden in the feed.
 */
- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn forSiteURL:(nonnull NSURL *)siteURL;

- (void)toggleAllContentGroupKinds:(BOOL)on completion:(nullable dispatch_block_t)completion;

/**
 Toggles non-language specific content group kinds (Because you read, Continue reading and Picture of the day)

 @param on A flag indicating whether non-language specific groups should be visible in the feed.
 */
- (void)toggleGlobalContentGroupKinds:(BOOL)on;

/**
 Returns a set of language codes representing languages in which a given content group kind is visible in the feed.

 @param contentGroupKind The kind of the content group whose language codes you want to get.
 @return A set of language codes representing languages in which a given content group kind is visible in the feed.
 If a given content group kind is not visible in any languages, the set will be empty.
 */
- (NSSet<NSString *> *_Nonnull)languageCodesForContentGroupKind:(WMFContentGroupKind)contentGroupKind;

/**
 Returns a flag indicating whether there are any customizable content groups visible in the feed for a given siteURL.
 */
- (BOOL)anyContentGroupsVisibleInTheFeedForSiteURL:(nonnull NSURL *)siteURL;

/**
 Returns a set of integers that represent customizable content group kinds.
 */
+ (nonnull NSSet<NSNumber *> *)customizableContentGroupKindNumbers;

/**
 Returns a set of integers that represent non-language specific content group kinds.
 */
+ (nonnull NSSet<NSNumber *> *)globalContentGroupKindNumbers;

/**
 Indicates whether non-language specific group kinds are visible in the feed.
 */
@property (nonatomic, readonly) BOOL areGlobalContentGroupKindsInFeed;

- (BOOL)isGlobalContentGroupKindInFeed:(WMFContentGroupKind)contentGroupKind;

- (void)saveNewExploreFeedPreferences:(nonnull NSDictionary *)newExploreFeedPreferences apply:(BOOL)apply updateFeed:(BOOL)updateFeed;
- (void)rejectNewExploreFeedPreferences;

- (void)dismissCollapsedContentGroups;

#if WMF_TWEAKS_ENABLED
- (void)debugSendRandomInTheNewsNotification;
#endif
#if DEBUG
- (void)debugChaos;
#endif

@end
