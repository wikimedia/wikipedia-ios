#import "UIViewController+WMFWelcomeNavigation.h"
#import "UINavigationBar+WMFTransparency.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

@implementation UIViewController (WMFWelcomeNavigation)

- (void)wmf_setupTransparentWelcomeNavigationBarWithBackChevron {
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar wmf_makeTransparent];
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    @weakify(self)
        UIButton *button = [UIButton wmf_buttonType:WMFButtonTypeCaretLeft
                                            handler:^(id sender) {
                                              @strongify(self)
                                                  [self.navigationController popViewControllerAnimated:YES];
                                            }];
    button.tintColor = [UIColor wmf_blueTintColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

@end
