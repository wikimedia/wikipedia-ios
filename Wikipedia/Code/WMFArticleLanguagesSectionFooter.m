#import "WMFArticleLanguagesSectionFooter.h"
#import "Wikipedia-Swift.h"

@interface WMFArticleLanguagesSectionFooter ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *addButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@end

@implementation WMFArticleLanguagesSectionFooter

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView = backgroundView;
    [self.addButton setTitle:WMFLocalizedStringWithDefaultValue(@"welcome-languages-add-button", nil, nil, @"Add another language", @"Title for button for adding another language")
                    forState:UIControlStateNormal];
    [self wmf_configureSubviewsForDynamicType];
    [self applyTheme:[WMFTheme standard]];
}

- (void)setButtonHidden:(BOOL)hidden {
    [self.addButton setHidden:hidden];
    self.topConstraint.constant = hidden ? 10 : 0;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.backgroundView.backgroundColor = theme.colors.baseBackground;
    self.titleLabel.textColor = theme.colors.secondaryText;
    [self.addButton setTitleColor:theme.colors.link forState:UIControlStateNormal];
}

- (IBAction)addLanguageButtonTapped:(id)sender {
    [self.delegate addLanguageButtonTapped];
}

@end
