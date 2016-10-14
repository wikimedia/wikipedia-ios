#import "WMFTimerContentSource.h"
#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticlePreviewDataStore;
@class WMFNotificationsController;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentSource : WMFTimerContentSource <WMFContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
