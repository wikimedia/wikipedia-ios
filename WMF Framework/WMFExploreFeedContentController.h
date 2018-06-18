#import "WMFContentGroup+Extensions.h"

@import UIKit;

@class MWKDataStore;

extern NSString *_Nonnull const WMFExploreFeedContentControllerBusyStateDidChange;

@interface WMFExploreFeedContentController : NSObject

@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, weak, nullable) MWKDataStore *dataStore;
@property (nonatomic, copy, nullable) NSArray<NSURL *> *siteURLs;

- (void)startContentSources;
- (void)stopContentSources;

- (void)cancelAllFetches;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;
- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;

- (void)updateNearbyForce:(BOOL)force completion:(nullable dispatch_block_t)completion;
- (void)updateBackgroundSourcesWithCompletion:(void (^_Nonnull)(UIBackgroundFetchResult))completionHandler;

// Preferences
- (void)updateExploreFeedPreferencesForSiteURLs:(nonnull NSSet<NSURL *> *)siteURLs shouldHideAllContentSources:(BOOL)shouldHideAllContentSources completion:(nullable dispatch_block_t)completion;
- (BOOL)anyContentSourcesVisibleInTheFeedForSiteURL:(nonnull NSURL *)siteURL;
- (NSSet<NSString *> *_Nonnull)languageCodesForContentGroupKind:(WMFContentGroupKind)contentGroupKind;


/**
 Toggles a content group of given kind on or off for all preferred languages.
 If it's on, the group will appear in the feed in all preferred languages.
 If it's off, the group will not appear in the feed at all.

 @param contentGroupKind The kind of the content group that is about to be toggled on/off in the feed.
 @param isOn Specifies whether the group should be visible in the feed or not.
 */
- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn;

#if WMF_TWEAKS_ENABLED
- (void)debugSendRandomInTheNewsNotification;
#endif
#if DEBUG
- (void)debugChaos;
#endif

@end
