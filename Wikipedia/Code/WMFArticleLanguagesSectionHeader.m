#import "WMFArticleLanguagesSectionHeader.h"

static CGFloat const WMFLanguageHeaderFontSize = 12.f;

@interface WMFArticleLanguagesSectionHeader ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation WMFArticleLanguagesSectionHeader

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = [UIColor wmf_settingsBackgroundColor];
    self.backgroundView = backgroundView;

    self.titleLabel.font = [UIFont systemFontOfSize:WMFLanguageHeaderFontSize];
    self.titleLabel.textColor = [UIColor wmf_777777Color];
}

@end
