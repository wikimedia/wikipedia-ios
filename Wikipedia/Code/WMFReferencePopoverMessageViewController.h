@import UIKit;
@import WMF.Swift;

NS_ASSUME_NONNULL_BEGIN

@class WMFLegacyReference;

extern NSString *const WMFReferenceLinkTappedNotification;

@interface WMFReferencePopoverMessageViewController : UIViewController <UIPopoverPresentationControllerDelegate, WMFThemeable>

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL scrollEnabled;

@property (strong, nonatomic, nullable) WMFLegacyReference *reference;
@property (strong, nonatomic, nullable) NSURL *articleURL;

- (void)scrollToTop;

@end

NS_ASSUME_NONNULL_END
