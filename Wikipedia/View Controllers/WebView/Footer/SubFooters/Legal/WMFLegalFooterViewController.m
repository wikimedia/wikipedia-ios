//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFLegalFooterViewController.h"
#import "NSString+FormattedAttributedString.h"
#import "NSObject+ConstraintsScale.h"
#import "WikipediaAppUtils.h"
#import "PaddedLabel.h"
#import "UIColor+WMFHexColor.h"
#import "Defines.h"

#pragma mark Font sizes

static const CGFloat kLicenseFontSize = 10.0f;

#pragma mark Colors

static const NSInteger kLicenseTextColor = 0x565656;
static const NSInteger kLicenseNameColor = 0x566893;

#pragma mark License URL

NSString* const kLicenseTitleOnENWiki =
    @"Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License";

#pragma mark Private properties

@interface WMFLegalFooterViewController ()

@property (nonatomic, weak) IBOutlet PaddedLabel* licenseLabel;
@property (nonatomic, weak) IBOutlet UIImageView* wordmarkImageView;

@end

@implementation WMFLegalFooterViewController

#pragma mark Setup / view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.licenseLabel.attributedText = [self getAttributedStringForLicense];
    [self adjustConstraintsScaleForViews:@[self.licenseLabel, self.wordmarkImageView]];
}

#pragma mark Style

- (NSAttributedString*)getAttributedStringForLicense {
    NSDictionary* baseStyle =
        @{
        NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kLicenseTextColor alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:kLicenseFontSize * MENUS_SCALE_MULTIPLIER]
    };

    NSDictionary* substitutionStyle =
        @{
        NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kLicenseNameColor alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:kLicenseFontSize * MENUS_SCALE_MULTIPLIER]
    };

    NSString* footerText = MWLocalizedString(@"license-footer-text", nil);

    return
        [footerText attributedStringWithAttributes:baseStyle
                               substitutionStrings:@[MWLocalizedString(@"license-footer-name", nil)]
                            substitutionAttributes:@[substitutionStyle]];
}

#pragma mark Tap gesture handling

- (IBAction)licenseTapped:(id)sender {
    MWKSite* site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    [NAV loadArticleWithTitle:[site titleWithString:kLicenseTitleOnENWiki]
                     animated:NO
              discoveryMethod:MWK_DISCOVERY_METHOD_SEARCH
                   popToWebVC:YES];
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
