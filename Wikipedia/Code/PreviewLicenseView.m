#import "PreviewLicenseView.h"
#import "PaddedLabel.h"
#import "NSString+FormattedAttributedString.h"
#import "WikiGlyph_Chars.h"
#import "UIFont+WMFStyle.h"
#import "Wikipedia-Swift.h"

#define PREVIEW_BLUE_COLOR [UIColor colorWithRed:0.2 green:0.4784 blue:1.0 alpha:1.0]

//#import "NSString+WMFExtras.h"

@interface PreviewLicenseView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDividerHeight;

@property (nonatomic) BOOL hideTopDivider;
@property (nonatomic) BOOL hideBottomDivider;

@end

@implementation PreviewLicenseView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.hideTopDivider = YES;
        self.hideBottomDivider = YES;
    }
    return self;
}

- (void)didMoveToSuperview {
    self.licenseTitleLabel.padding = UIEdgeInsetsMake(2, 0, 0, 0);

    self.licenseTitleLabel.font = [UIFont systemFontOfSize:11.0];
    self.licenseLoginLabel.font = [UIFont systemFontOfSize:11.0];

    self.licenseTitleLabel.text = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-terms-and-license", nil, nil, @"By publishing, you agree to the %1$@, and to irrevocably release your contributions under the %2$@ license.", @"Button text for information about the Terms of Use and edit license. Parameters:\n* %1$@ - 'Terms of Use' link ([[Wikimedia:Wikipedia-ios-wikitext-upload-save-terms-name]])\n* %2$@ - license name link");
    [self styleLinks:self.licenseTitleLabel];
    [self.licenseTitleLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(termsLicenseLabelTapped:)]];

    self.licenseLoginLabel.text = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-anonymously-warning", nil, nil, @"Edits will be attributed to the IP address of your device. If you %1$@ you will have more privacy.", @"Button sub-text informing user or draw-backs of not signing in before saving wikitext. Parameters:\n* %1$@ - sign in button text");
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
           NSForegroundColorAttributeName: PREVIEW_BLUE_COLOR
        };

    label.attributedText =
        [label.text attributedStringWithAttributes:baseAttributes
                               substitutionStrings:@[WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-terms-name", nil, nil, @"Terms of Use", @"This message is used in the message [[Wikimedia:Wikipedia-ios-wikitext-upload-save-terms-and-license]].\n{{Identical|Terms of use}}"),
                                                     WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-license-name", nil, nil, @"CC BY-SA 3.0", @"Name of license user edits are saved under - presently CC BY-SA 3.0\n{{Identical|CC BY-SA}}")]
                            substitutionAttributes:@[linkAttributes, linkAttributes]];
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
            NSForegroundColorAttributeName: PREVIEW_BLUE_COLOR
        };

    label.attributedText =
        [label.text attributedStringWithAttributes:baseAttributes
                               substitutionStrings:@[WMFLocalizedStringWithDefaultValue(@"wikitext-upload-save-sign-in", nil, nil, @"Log in", @"{{Identical|Log in}}")]
                            substitutionAttributes:@[substitutionAttributes]];
}

- (NSAttributedString *)getCCIconAttributedString {
    return [[NSAttributedString alloc] initWithString:WIKIGLYPH_CC
                                           attributes:@{
                                               NSFontAttributeName: [UIFont wmf_glyphFontOfSize:42.0],
                                               NSForegroundColorAttributeName: PREVIEW_BLUE_COLOR,
                                               NSBaselineOffsetAttributeName: @1.5
                                           }];
}

@end
