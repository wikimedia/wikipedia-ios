#import "PreviewLicenseView.h"
#import "PaddedLabel.h"
#import "NSString+FormattedAttributedString.h"
#import "WikiGlyph_Chars.h"
#import "Wikipedia-Swift.h"

@interface PreviewLicenseView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDividerHeight;

@property (nonatomic) BOOL hideTopDivider;
@property (nonatomic) BOOL hideBottomDivider;

@property (nonatomic, strong) WMFTheme *theme;

@end

@implementation PreviewLicenseView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.theme = [WMFTheme standard];
        self.hideTopDivider = YES;
        self.hideBottomDivider = YES;
    }
    return self;
}

- (void)didMoveToSuperview {
    self.licenseTitleLabel.padding = UIEdgeInsetsMake(2, 0, 0, 0);

    self.licenseTitleLabel.font = [UIFont systemFontOfSize:11.0];
    self.licenseLoginLabel.font = [UIFont systemFontOfSize:11.0];

    self.licenseTitleLabel.text = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-terms-cc-by-sa-and-gfdl", nil, nil, @"By publishing changes, you agree to the %1$@ and agree to release your contribution under the %2$@ and %3$@ license.", @"Button text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - 'Terms of Use' link ([[Wikimedia:Wikipedia-ios-wikitext-upload-save-terms-name]])\n* %2$@ - license name link 1\n* %3$@ - license name link 2");
    [self styleLinks:self.licenseTitleLabel];
    [self.licenseTitleLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(termsLicenseLabelTapped:)]];

    self.licenseLoginLabel.text = [WMFCommonStrings editAttribution];
    [self underlineSignIn:self.licenseLoginLabel];

    self.licenseCCLabel.attributedText = [self getCCIconAttributedString];

    self.bottomDividerHeight.constant = self.hideBottomDivider ? 0.0 : 1.0f / [UIScreen mainScreen].scale;

    self.topDividerHeight.constant = self.hideTopDivider ? 0.0 : 1.0f / [UIScreen mainScreen].scale;

    //self.licenseTitleLabel.text = [@" abc " randomlyRepeatMaxTimes:100];
}

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    BOOL isPlaceholder = ([[self subviews] count] == 0); // From: https://blog.compeople.eu/apps/?p=142
    if (!isPlaceholder) {
        return self;
    }

    UINib *previewLicenseViewNib = [UINib nibWithNibName:@"PreviewLicenseView" bundle:nil];

    PreviewLicenseView *previewLicenseView =
        [[previewLicenseViewNib instantiateWithOwner:nil options:nil] firstObject];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    previewLicenseView.translatesAutoresizingMaskIntoConstraints = NO;

    return previewLicenseView;
}

- (void)styleLinks:(UILabel *)label {
    NSDictionary *baseAttributes =
        @{
            NSForegroundColorAttributeName: label.textColor,
            NSFontAttributeName: label.font
        };

    NSDictionary *linkAttributes =
        @{
            //NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName: self.theme.colors.link
        };

    label.attributedText = [label.text attributedStringWithAttributes:baseAttributes
                                                  substitutionStrings:@[WMFLicenses.localizedSaveTermsTitle, WMFLicenses.localizedCCBYSA3Title, WMFLicenses.localizedGFDLTitle]
                                               substitutionAttributes:@[linkAttributes, linkAttributes, linkAttributes]];
}

- (void)termsLicenseLabelTapped:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.previewLicenseViewDelegate previewLicenseViewTermsLicenseLabelWasTapped:self];
    }
}

- (void)underlineSignIn:(UILabel *)label {
    NSDictionary *baseAttributes =
        @{
            NSForegroundColorAttributeName: label.textColor,
            NSFontAttributeName: label.font
        };

    NSDictionary *substitutionAttributes =
        @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName: self.theme.colors.link
        };

    label.attributedText =
        [label.text attributedStringWithAttributes:baseAttributes
                               substitutionStrings:@[[WMFCommonStrings editSignIn]]
                            substitutionAttributes:@[substitutionAttributes]];
}

- (NSAttributedString *)getCCIconAttributedString {
    return [[NSAttributedString alloc] initWithString:WIKIGLYPH_CC
                                           attributes:@{
                                               NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:42.0],
                                               NSForegroundColorAttributeName: self.theme.colors.link,
                                               NSBaselineOffsetAttributeName: @1.5
                                           }];
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.backgroundColor = theme.colors.paperBackground;
}
@end
