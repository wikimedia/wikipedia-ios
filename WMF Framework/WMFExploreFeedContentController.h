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

#if WMF_TWEAKS_ENABLED
- (void)debugSendRandomInTheNewsNotification;
#endif
#if DEBUG
- (void)debugChaos;
#endif

@end
