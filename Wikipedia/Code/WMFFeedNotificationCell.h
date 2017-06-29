#import "WMFExploreCollectionViewCell.h"

@class WMFLeadingImageTrailingTextButton;

@protocol WMFFeedNotificationCellDelegate;

@interface WMFFeedNotificationCell : WMFExploreCollectionViewCell

@property (weak, nonatomic) id <WMFFeedNotificationCellDelegate> notificationCellDelegate;

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet WMFLeadingImageTrailingTextButton *enableNotificationsButton;

@end

@protocol WMFFeedNotificationCellDelegate <NSObject>

- (void)feedNotificationCellDidRequestEnableNotifications:(WMFFeedNotificationCell *)cell;

@end
