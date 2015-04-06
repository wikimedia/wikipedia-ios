
#import <UIKit/UIKit.h>

@interface UIViewController (HideKeyboard)

/**
 *  Uses the responder chain to make all UIResponders
 *  in the view hierarchy resignFirstResponder.
 */
- (void)hideKeyboard;

@end
