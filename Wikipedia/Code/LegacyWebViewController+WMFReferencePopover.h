#import "LegacyWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFReferenceLinkTappedNotification;
@class WMFReference;

@interface LegacyWebViewController (WMFReferencePopover)

- (void)wmf_presentReferencePopoverViewControllerForReference:(WMFReference *)reference
                                                        width:(CGFloat)width;

- (void)wmf_dismissReferencePopoverAnimated:(BOOL)flag completion:(void (^__nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
