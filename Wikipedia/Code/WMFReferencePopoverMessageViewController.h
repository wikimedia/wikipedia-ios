#import <UIKit/UIKit.h>

extern NSString *const WMFReferencePopoverShowNextNotification;
extern NSString *const WMFReferencePopoverShowPreviousNotification;

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString *linkText;
@property (strong, nonatomic) NSString *HTML;
@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

- (void) scrollToTop;

@end
