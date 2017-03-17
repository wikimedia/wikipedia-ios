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
    backgroundView.backgroundColor = [UIColor wmf_settingsBackground];
    self.backgroundView = backgroundView;
    self.titleLabel.textColor = [UIColor wmf_777777];
    [self wmf_configureSubviewsForDynamicType];
}

@end
