
#import "UIViewController+HideKeyboard.h"

@implementation UIViewController (HideKeyboard)

- (void)hideKeyboard {
    //http://stackoverflow.com/questions/11879745/an-utility-method-for-hiding-the-keyboard
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

@end
