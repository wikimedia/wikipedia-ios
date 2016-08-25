#import <UIKit/UIKit.h>

@interface UIBarButtonItem (WMFDynamicHeightPopoverMessage)

- (UIViewController*)wmf_dynamicHeightPopoverViewControllerWithTitle:(NSString*)title
                                                             message:(NSString*)message
                                                               width:(CGFloat)width;

@end
