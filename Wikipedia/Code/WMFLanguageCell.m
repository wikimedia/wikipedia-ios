#import "WMFLanguageCell.h"
#import "Wikipedia-Swift.h"

@interface WMFLanguageCell ()

@property (strong, nonatomic) IBOutlet UILabel *localizedLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *articleTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *languageNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *primaryLabel;
@property (strong, nonatomic) IBOutlet UIView *primaryLabelContainerView;
@property (strong, nonatomic) WMFTheme *theme;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;

@end

@implementation WMFLanguageCell

- (void)setLocalizedLanguageName:(NSString *)localizedLanguageName {
    _localizedLanguageName = localizedLanguageName;
    self.localizedLanguageLabel.text = localizedLanguageName;
}

- (void)setArticleTitle:(NSString *)articleTitle {
    _articleTitle = articleTitle;
    self.articleTitleLabel.text = articleTitle;
}

- (void)setLanguageName:(NSString *)languageName {
    if (![self shouldShowLanguageName:languageName]) {
        self.localizedLanguageLabel.text = nil;
    }
    _languageName = languageName;
    self.languageNameLabel.text = [languageName wmf_stringByCapitalizingFirstCharacterUsingWikipediaLanguage:nil];
}

- (BOOL)shouldShowLanguageName:(NSString *)languageName {
    return ![languageName isEqualToString:self.localizedLanguageName];
}

- (void)setLanguageID:(NSString *)languageID {
    _languageID = languageID;
    _articleTitleLabel.accessibilityLanguage = languageID;
    _languageNameLabel.accessibilityLanguage = languageID;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepareForReuse];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    [self wmf_configureSubviewsForDynamicType];
    [self applyTheme:[WMFTheme standard]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.languageNameLabel.text = nil;
    self.articleTitleLabel.text = nil;
    self.localizedLanguageLabel.text = nil;
    self.isPrimary = NO;
    self.isPreferred = NO;
}

- (void)collapseSideSpacing {
    self.leadingConstraint.constant = 0;
    self.trailingConstraint.constant = 0;
}

- (void)setIsPrimary:(BOOL)isPrimary {
    _isPrimary = isPrimary;
    if (isPrimary) {
        self.primaryLabel.text = [WMFLocalizedStringWithDefaultValue(@"settings-primary-language", nil, nil, @"Primary", @"Label shown next to primary language {{Identical|Primary}}") uppercaseStringWithLocale:[NSLocale currentLocale]];
        self.primaryLabelContainerView.backgroundColor = self.theme.colors.secondaryText;
    } else {
        self.primaryLabel.text = nil;
        self.primaryLabelContainerView.backgroundColor = [UIColor clearColor];
    }
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.localizedLanguageLabel.textColor = theme.colors.secondaryText;
    self.articleTitleLabel.textColor = theme.colors.secondaryText;
    self.languageNameLabel.textColor = theme.colors.primaryText;
    self.primaryLabel.textColor = theme.colors.paperBackground;
    self.backgroundView.backgroundColor = theme.colors.paperBackground;
    self.selectedBackgroundView.backgroundColor = theme.colors.midBackground;
    self.localizedLanguageLabel.textColor = theme.colors.secondaryText;
    self.articleTitleLabel.textColor = theme.colors.secondaryText;
    [self setIsPrimary:_isPrimary];
}

@end
