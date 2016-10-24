#import <UIKit/UIKit.h>

extern NSString *const WMFReferencePopoverShowNextNotification;
extern NSString *const WMFReferencePopoverShowPreviousNotification;

@class WMFReference;

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@property(strong, nonatomic) WMFReference *reference;

- (void) scrollToTop;

@end
