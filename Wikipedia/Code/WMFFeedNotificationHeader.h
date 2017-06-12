@class WMFLeadingImageTrailingTextButton;
@import WMF.Swift;

@interface WMFFeedNotificationHeader : UIView <WMFAnalyticsContextProviding, WMFAnalyticsContentTypeProviding>

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet WMFLeadingImageTrailingTextButton *enableNotificationsButton;

@end
