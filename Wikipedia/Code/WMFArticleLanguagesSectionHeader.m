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
    self.backgroundView = backgroundView;
    [self wmf_configureSubviewsForDynamicType];
    [self applyTheme:[WMFTheme standard]];
}

- (void)applyTheme:(WMFTheme *)theme {
    self.backgroundView.backgroundColor = theme.colors.baseBackground;
    self.titleLabel.textColor = theme.colors.secondaryText;
}

@end
