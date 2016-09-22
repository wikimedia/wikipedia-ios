#import <UIKit/UIKit.h>

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString *linkText;
@property (strong, nonatomic) NSString *HTML;
@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@end
