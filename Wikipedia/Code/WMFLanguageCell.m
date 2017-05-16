#import "WMFLanguageCell.h"
#import "UILabel+WMFStyling.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "NSString+WMFExtras.h"
#import "Wikipedia-Swift.h"

@interface WMFLanguageCell ()

@property (strong, nonatomic) IBOutlet UILabel *localizedLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *articleTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *languageNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *primaryLabel;
@property (strong, nonatomic) IBOutlet UIView *primaryLabelContainerView;

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
    self.languageNameLabel.text = [languageName wmf_stringByCapitalizingFirstCharacter];
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
    [self wmf_makeCellDividerBeEdgeToEdge];
    self.localizedLanguageLabel.textColor = [UIColor wmf_777777];
    self.articleTitleLabel.textColor = [UIColor wmf_777777];
    [self wmf_configureSubviewsForDynamicType];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.languageNameLabel.text = nil;
    self.articleTitleLabel.text = nil;
    self.localizedLanguageLabel.text = nil;
    self.isPrimary = NO;
    self.isPreferred = NO;
}

- (void)setIsPrimary:(BOOL)isPrimary {
    _isPrimary = isPrimary;
    if (isPrimary) {
        self.primaryLabel.text = [WMFLocalizedStringWithDefaultValue(@"settings-primary-language", nil, nil, @"Primary", @"Label shown next to primary language\n{{Identical|Primary}}") uppercaseStringWithLocale:[NSLocale currentLocale]];
        self.primaryLabelContainerView.backgroundColor = [UIColor wmf_primaryLanguageLabelBackground];
    } else {
        self.primaryLabel.text = nil;
        self.primaryLabelContainerView.backgroundColor = [UIColor clearColor];
    }
}

@end
