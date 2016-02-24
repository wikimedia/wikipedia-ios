#import "UIButton+WMFWelcomeNextButton.h"

@implementation UIButton (WMFWelcomeNextButton)

- (void)wmf_configureAsWelcomeNextButton {
    [self setTitle:[MWLocalizedString(@"welcome-languages-continue-button", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]
                         forState:UIControlStateNormal];
    self.backgroundColor = [UIColor wmf_welcomeNextButtonBackgroundColor];
    [self setTitleColor:[UIColor wmf_blueTintColor] forState:UIControlStateNormal];
}

@end
