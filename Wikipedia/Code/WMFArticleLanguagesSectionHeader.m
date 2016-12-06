#import "WMFArticleLanguagesSectionHeader.h"
#import "Wikipedia-Swift.h"

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
    self.titleLabel.textColor = [UIColor wmf_777777Color];
    [self wmf_configureSubviewsForDynamicType];
}

@end
