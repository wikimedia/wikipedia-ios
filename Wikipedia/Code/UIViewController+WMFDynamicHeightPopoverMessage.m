#import "UIViewController+WMFDynamicHeightPopoverMessage.h"
#import "UIBarButtonItem+WMFDynamicHeightPopoverMessage.h"

@implementation UIViewController (WMFDynamicHeightPopoverMessage)

- (void)wmf_presentDynamicHeightPopoverViewControllerForBarButtonItem:(UIBarButtonItem*)item
                                                            withTitle:(NSString*)title
                                                              message:(NSString*)message {
    [self presentViewController:
     [item wmf_dynamicHeightPopoverViewControllerWithTitle:title
                                                   message:message
                                                     width:230.0]
                       animated:NO
                     completion:nil];
}

@end
