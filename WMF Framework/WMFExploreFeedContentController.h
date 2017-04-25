#import <Foundation/Foundation.h>

@interface WMFExploreFeedContentController : NSObject

@property (nonatomic, weak, nullable) MWKDataStore *dataStore;
@property (nonatomic, copy, nullable) NSURL *siteURL;

- (void)startContentSources;
- (void)stopContentSources;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;
- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;

- (void)updateNearbyForce:(BOOL)force completion:(nullable dispatch_block_t)completion;
- (void)updateBackgroundSourcesWithCompletion:(void (^_Nonnull)(UIBackgroundFetchResult))completionHandler;

- (void)debugSendRandomInTheNewsNotification;
- (void)debugChaos;

@end
