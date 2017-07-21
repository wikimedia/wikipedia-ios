#import "WMFExploreCollectionViewCell.h"
@import WMF.Swift;

@class WMFLeadingImageTrailingTextButton;

@protocol WMFFeedNotificationCellDelegate;

@interface WMFFeedNotificationCell : WMFExploreCollectionViewCell <WMFThemeable>

@property (weak, nonatomic) id <WMFFeedNotificationCellDelegate> notificationCellDelegate;

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet WMFLeadingImageTrailingTextButton *enableNotificationsButton;
@property (strong, nonatomic) IBOutlet UIView *visibleBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@end

@protocol WMFFeedNotificationCellDelegate <NSObject>

- (void)feedNotificationCellDidRequestEnableNotifications:(WMFFeedNotificationCell *)cell;
- (void)feedNotificationCellDidDismiss:(WMFFeedNotificationCell *)cell;

@end
