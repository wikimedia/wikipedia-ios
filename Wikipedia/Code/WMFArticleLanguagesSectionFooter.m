#import "WMFArticleLanguagesSectionFooter.h"
#import "Wikipedia-Swift.h"

@interface WMFArticleLanguagesSectionFooter ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *addButton;

@end

@implementation WMFArticleLanguagesSectionFooter

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = [UIColor wmf_settingsBackground];
    self.backgroundView = backgroundView;
    self.titleLabel.textColor = [UIColor wmf_777777];
    [self.addButton setTitle:WMFLocalizedStringWithDefaultValue(@"welcome-languages-add-button", nil, nil, @"Add another language", @"Title for button for adding another language")
                    forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor wmf_blueTint] forState:UIControlStateNormal];
    [self wmf_configureSubviewsForDynamicType];
}

@end
