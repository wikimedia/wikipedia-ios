#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticlePreviewDataStore;
@class WMFNotificationsController;
@class MWKDataStore;
@class WMFFeedNewsStory;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory articlePreview:(WMFArticlePreview *)articlePreview force:(BOOL)force;

- (void)clearCache:(nonnull dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
