#import <Foundation/Foundation.h>

@interface WMFExploreFeedContentController : NSObject

@property (nonatomic, weak, nullable) MWKDataStore *dataStore;
@property (nonatomic, copy, nullable) NSURL *siteURL;

- (void)startContentSources;
- (void)stopContentSources;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;
- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion;

- (void)updateNearby:(nullable dispatch_block_t)completion;
- (void)updateBackgroundSourcesWithCompletion:(nullable dispatch_block_t)completion;

- (void)debugSendRandomInTheNewsNotification;

@end
