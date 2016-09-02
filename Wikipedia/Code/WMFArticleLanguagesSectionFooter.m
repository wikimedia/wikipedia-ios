#import "WMFArticleLanguagesSectionFooter.h"

static CGFloat const WMFLanguageFooterFontSize = 14.f;

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
    backgroundView.backgroundColor = [UIColor wmf_settingsBackgroundColor];
    self.backgroundView = backgroundView;

    self.titleLabel.font = [UIFont systemFontOfSize:WMFLanguageFooterFontSize];
    self.titleLabel.textColor = [UIColor wmf_777777Color];

    [self.addButton setTitle:MWLocalizedString(@"welcome-languages-add-button", nil)
                    forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor wmf_blueTintColor] forState:UIControlStateNormal];
}

@end
