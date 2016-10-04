#import <Foundation/Foundation.h>


extern NSString *const WMFInTheNewsNotificationCategoryIdentifier;
extern NSString *const WMFInTheNewsNotificationReadNowActionIdentifier;
extern NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier;
extern NSString *const WMFInTheNewsNotificationShareActionIdentifier;

extern NSString *const WMFNotificationInfoStoryHTMLKey;
extern NSString *const WMFNotificationInfoArticleTitleKey;
extern NSString *const WMFNotificationInfoArticleURLStringKey;
extern NSString *const WMFNotificationInfoThumbnailURLStringKey;
extern NSString *const WMFNotificationInfoArticleExtractKey;
extern NSString *const WMFNotificationInfoViewCountsKey;

@interface WMFNotificationsController : NSObject

- (void)start;
- (void)stop;

@end
