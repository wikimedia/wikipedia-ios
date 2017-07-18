@import UIKit;
@import WMF.Swift;

@interface WMFBarButtonItemPopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate, WMFThemeable>

@property (strong, nonatomic) NSString *messageTitle;
@property (strong, nonatomic) NSString *message;
@property (nonatomic) CGFloat width;

@end
