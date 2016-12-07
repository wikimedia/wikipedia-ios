#import <UIKit/UIKit.h>
@class WMFLeadingImageTrailingTextButton;
#import "PiwikTracker+WMFExtensions.h"

@interface WMFFeedNotificationHeader : UIView <WMFAnalyticsContextProviding, WMFAnalyticsContentTypeProviding>

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet WMFLeadingImageTrailingTextButton *enableNotificationsButton;

@end
