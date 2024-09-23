@import UIKit;
@import WMF.Swift;

@interface WMFBarButtonItemPopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString *messageTitle;
@property (strong, nonatomic) NSString *message;
@property (nonatomic) CGFloat width;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;

@end
