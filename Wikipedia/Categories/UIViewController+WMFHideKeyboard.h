
#import <UIKit/UIKit.h>

@interface UIViewController (WMFHideKeyboard)

/**
 *  Uses the responder chain to make all UIResponders
 *  in the view hierarchy resignFirstResponder.
 */
- (void)wmf_hideKeyboard;

@end
