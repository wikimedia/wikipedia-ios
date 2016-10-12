#import "UIButton+WMFWelcomeNextButton.h"

@implementation UIButton (WMFWelcomeNextButton)

- (void)wmf_configureAsWelcomeNextButton {
    [self setTitle:[MWLocalizedString(@"welcome-languages-continue-button", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]
          forState:UIControlStateNormal];
}

@end
