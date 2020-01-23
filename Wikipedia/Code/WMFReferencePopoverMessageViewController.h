@import UIKit;
@import WMF.Swift;

@class WMFReference;

extern NSString *const WMFReferenceLinkTappedNotification;

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate, WMFThemeable>

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@property (strong, nonatomic) WMFReference *reference;

- (void)scrollToTop;

@end
