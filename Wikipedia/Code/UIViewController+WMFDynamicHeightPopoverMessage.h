#import <UIKit/UIKit.h>

@interface UIViewController (WMFDynamicHeightPopoverMessage)

- (void)wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:(UIBarButtonItem*)item
                                                            withTitle:(NSString*)title
                                                              message:(NSString*)message;
@end
