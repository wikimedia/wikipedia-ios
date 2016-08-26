#import <UIKit/UIKit.h>

@interface UIViewController (WMFDynamicHeightPopoverMessage)

- (void)wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:(UIBarButtonItem*)item
                                                            withTitle:(NSString*)title
                                                              message:(NSString*)message
                                                                width:(CGFloat)width;

- (void)wmf_presentDynamicHeightPopoverViewControllerForSourceRect:(CGRect)sourceRect
                                                         withTitle:(NSString*)title
                                                           message:(NSString*)message
                                                             width:(CGFloat)width;
@end
