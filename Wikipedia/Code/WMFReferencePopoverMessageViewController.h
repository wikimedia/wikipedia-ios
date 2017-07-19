@import UIKit;
@import WMF.Swift;

@class WMFReference;

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate, WMFThemeable>

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@property (strong, nonatomic) WMFReference *reference;

- (void)scrollToTop;

@end
