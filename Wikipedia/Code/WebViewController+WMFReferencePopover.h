#import <UIKit/UIKit.h>
#import "WebViewController.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFReferenceLinkTappedNotification;

@interface WebViewController (WMFReferencePopover)

- (void)wmf_presentReferencePopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                      linkText:(nullable NSString *)linkText
                                                          HTML:(nullable NSString *)html
                                                         width:(CGFloat)width;

- (void)wmf_dismissReferencePopoverAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
