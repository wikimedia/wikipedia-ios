#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticlePreviewDataStore;
@class WMFNotificationsController;
@class MWKDataStore;
@class WMFFeedNewsStory;
@class WMFFeedDayResponse;
@class WMFArticlePreview;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, getter=isNotificationSchedulingEnabled) BOOL notificationSchedulingEnabled;

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readonly, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory articlePreview:(WMFArticlePreview *)articlePreview force:(BOOL)force;

//Use this method to fetch content directly. Using this will not persist the results
- (void)fetchContentForDate:(NSDate *)date force:(BOOL)force completion:(void (^)(WMFFeedDayResponse *__nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *__nullable pageViews))completion;

@end

NS_ASSUME_NONNULL_END
