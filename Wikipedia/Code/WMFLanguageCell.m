//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFLanguageCell.h"
#import "WikipediaAppUtils.h"
#import "UILabel+WMFStyling.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

static CGFloat const WMFPreferredLanguageFontSize = 15.f;
static CGFloat const WMFPreferredTitleFontSize    = 12.f;
static CGFloat const WMFOtherLanguageFontSize     = 15.f;
static CGFloat const WMFOtherTitleFontSize        = 12.f;
static CGFloat const WMFLanguageNameLabelHeight   = 18.f;

@interface WMFLanguageCell ()

@property (strong, nonatomic) IBOutlet UILabel* localizedLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel* articleTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel* languageNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* primaryLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* languageNameLabelHeight;

@end

@implementation WMFLanguageCell

- (void)setIsPreferred:(BOOL)isPreferred {
    _isPreferred = isPreferred;
    if (isPreferred) {
        self.localizedLanguageLabel.font = [UIFont systemFontOfSize:WMFPreferredLanguageFontSize];
        self.articleTitleLabel.font      = [UIFont systemFontOfSize:WMFPreferredTitleFontSize];
        self.languageNameLabel.font      = [UIFont systemFontOfSize:WMFPreferredTitleFontSize];
    } else {
        self.localizedLanguageLabel.font = [UIFont systemFontOfSize:WMFOtherLanguageFontSize];
        self.articleTitleLabel.font      = [UIFont systemFontOfSize:WMFOtherTitleFontSize];
        self.languageNameLabel.font      = [UIFont systemFontOfSize:WMFOtherTitleFontSize];
    }
}

- (void)setLocalizedLanguageName:(NSString*)localizedLanguageName {
    _localizedLanguageName           = localizedLanguageName;
    self.localizedLanguageLabel.text = localizedLanguageName;
}

- (void)setArticleTitle:(NSString*)articleTitle {
    _articleTitle               = articleTitle;
    self.articleTitleLabel.text = articleTitle;
}

- (void)setLanguageName:(NSString*)languageName {
    if ([self shouldShowLanguageName:languageName]) {
        self.languageNameLabelHeight.constant = WMFLanguageNameLabelHeight;
    }
    _languageName               = languageName;
    self.languageNameLabel.text = languageName;
}

- (BOOL)shouldShowLanguageName:(NSString*)languageName {
    return ![languageName isEqualToString:self.localizedLanguageName];
}

- (void)setLanguageID:(NSString*)languageID {
    _languageID                              = languageID;
    _articleTitleLabel.accessibilityLanguage = languageID;
    _languageNameLabel.accessibilityLanguage = languageID;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepareForReuse];
    [self wmf_makeCellDividerBeEdgeToEdge];
    self.showsReorderControl = YES;
    self.primaryLabel.textColor = [UIColor whiteColor];
    self.primaryLabel.backgroundColor = [UIColor colorWithRed:0.8039 green:0.8039 blue:0.8039 alpha:1.0];
    self.isPrimary = NO;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.languageNameLabel.text           = @"";
    self.articleTitleLabel.text           = @"";
    self.localizedLanguageLabel.text      = @"";
    self.languageNameLabelHeight.constant = 0.f;
    self.isPrimary = NO;
}

- (void)setIsPrimary:(BOOL)isPrimary {
    _isPrimary = isPrimary;
    self.primaryLabel.text = isPrimary ? [NSString stringWithFormat:@"   %@   ", [MWLocalizedString(@"settings-primary-language", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]] : @"";
}

@end
