#import <UIKit/UIKit.h>

@interface WMFBarButtonItemPopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString* messageTitle;
@property (strong, nonatomic) NSString* message;
@property (nonatomic) CGFloat width;

@end
