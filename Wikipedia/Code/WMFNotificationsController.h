@import Foundation;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFInTheNewsNotificationCategoryIdentifier;
extern NSString *const WMFInTheNewsNotificationReadNowActionIdentifier;
extern NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier;
extern NSString *const WMFInTheNewsNotificationShareActionIdentifier;

extern NSString *const WMFEditRevertedNotificationCategoryIdentifier;
extern NSString *const WMFEditRevertedReadMoreActionIdentifier;
extern NSString *const WMFEditRevertedNotificationIDKey;

extern NSString *const WMFNotificationInfoArticleTitleKey;
extern NSString *const WMFNotificationInfoArticleURLStringKey;
extern NSString *const WMFNotificationInfoThumbnailURLStringKey;
extern NSString *const WMFNotificationInfoArticleExtractKey;
extern NSString *const WMFNotificationInfoViewCountsKey;
extern NSString *const WMFNotificationInfoFeedNewsStoryKey;

@class MWKDataStore;

@interface WMFNotificationsController : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, getter=isAuthorized) BOOL authorized;
@property (nonatomic, getter=isApplicationActive) BOOL applicationActive;

- (void)requestAuthenticationIfNecessaryWithCompletionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler;

- (void)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents; //null date components will send the notification ASAP

/// Registers notification categories for the app. Should only be called once at launch.
- (void)updateCategories;

@end

NS_ASSUME_NONNULL_END
