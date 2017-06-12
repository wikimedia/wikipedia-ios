@import UIKit;

@interface UIViewController (WMFDynamicHeightPopoverMessage)

- (void)wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:(UIBarButtonItem *)item
                                                            withTitle:(NSString *)title
                                                              message:(NSString *)message
                                                                width:(CGFloat)width
                                                             duration:(NSTimeInterval)duration;

- (void)wmf_presentDynamicHeightPopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                         withTitle:(NSString *)title
                                                           message:(NSString *)message
                                                             width:(CGFloat)width
                                                          duration:(NSTimeInterval)duration;
@end
