#import "WMFLanguageCell.h"
#import "WikipediaAppUtils.h"
#import "UILabel+WMFStyling.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "NSString+WMFExtras.h"

static CGFloat const WMFPreferredLanguageFontSize = 15.f;
static CGFloat const WMFPreferredTitleFontSize = 12.f;
static CGFloat const WMFOtherLanguageFontSize = 15.f;
static CGFloat const WMFOtherTitleFontSize = 12.f;
static CGFloat const WMFLocalizedLanguageLabelHeight = 18.f;

@interface WMFLanguageCell ()

@property(strong, nonatomic) IBOutlet UILabel *localizedLanguageLabel;
@property(strong, nonatomic) IBOutlet UILabel *articleTitleLabel;
@property(strong, nonatomic) IBOutlet UILabel *languageNameLabel;
@property(strong, nonatomic) IBOutlet UILabel *primaryLabel;
@property(strong, nonatomic) IBOutlet UIView *primaryLabelContainerView;

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *localizedLanguageLabelHeight;

@end

@implementation WMFLanguageCell

- (void)setIsPreferred:(BOOL)isPreferred {
  _isPreferred = isPreferred;
  if (isPreferred) {
    self.localizedLanguageLabel.font = [UIFont systemFontOfSize:WMFPreferredTitleFontSize];
    self.articleTitleLabel.font = [UIFont systemFontOfSize:WMFPreferredTitleFontSize];
    self.languageNameLabel.font = [UIFont systemFontOfSize:WMFPreferredLanguageFontSize];
  } else {
    self.localizedLanguageLabel.font = [UIFont systemFontOfSize:WMFOtherTitleFontSize];
    self.articleTitleLabel.font = [UIFont systemFontOfSize:WMFOtherTitleFontSize];
    self.languageNameLabel.font = [UIFont systemFontOfSize:WMFOtherLanguageFontSize];
  }
}

- (void)setLocalizedLanguageName:(NSString *)localizedLanguageName {
  _localizedLanguageName = localizedLanguageName;
  self.localizedLanguageLabel.text = localizedLanguageName;
}

- (void)setArticleTitle:(NSString *)articleTitle {
  _articleTitle = articleTitle;
  self.articleTitleLabel.text = articleTitle;
}

- (void)setLanguageName:(NSString *)languageName {
  if ([self shouldShowLanguageName:languageName]) {
    self.localizedLanguageLabelHeight.constant = WMFLocalizedLanguageLabelHeight;
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
  self.localizedLanguageLabel.textColor = [UIColor wmf_777777Color];
  self.articleTitleLabel.textColor = [UIColor wmf_777777Color];
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.languageNameLabel.text = nil;
  self.articleTitleLabel.text = nil;
  self.localizedLanguageLabel.text = nil;
  self.localizedLanguageLabelHeight.constant = 0.f;
  self.isPrimary = NO;
  self.isPreferred = NO;
}

- (void)setIsPrimary:(BOOL)isPrimary {
  _isPrimary = isPrimary;
  if (isPrimary) {
    self.primaryLabel.text = [MWLocalizedString(@"settings-primary-language", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.primaryLabelContainerView.backgroundColor = [UIColor wmf_primaryLanguageLabelBackgroundColor];
  } else {
    self.primaryLabel.text = nil;
    self.primaryLabelContainerView.backgroundColor = [UIColor clearColor];
  }
}

@end
