#import <WMF/WMFContentSource.h>

@class WMFNotificationsController;
@class MWKDataStore;
@class WMFFeedNewsStory;
@class WMFFeedDayResponse;
@class WMFArticle;

NS_ASSUME_NONNULL_BEGIN

extern NSInteger const WMFFeedNotificationMinHour;
extern NSInteger const WMFFeedNotificationMaxHour;
extern NSInteger const WMFFeedNotificationMaxPerDay;

@interface WMFFeedContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, getter=isNotificationSchedulingEnabled) BOOL notificationSchedulingEnabled;

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory articlePreview:(WMFArticle *)articlePreview inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force;

//Use this method to fetch content directly. Using this will not persist the results
- (void)fetchContentForDate:(NSDate *)date force:(BOOL)force completion:(void (^)(WMFFeedDayResponse *__nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *__nullable pageViews))completion;

@end

NS_ASSUME_NONNULL_END
