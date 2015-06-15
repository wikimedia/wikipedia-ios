//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFOptionsFooterViewController.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyphLabel.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "NSString+FormattedAttributedString.h"
#import "UIColor+WMFHexColor.h"
#import "UIView+WMFRoundCorners.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "PageHistoryViewController.h"

#pragma mark Font sizes

static CGFloat const kGlyphButtonFontSize   = 23.0f;
static CGFloat const kOptionTextFontSize    = 12.0f;
static CGFloat const kOptionTextLineSpacing = 2.0f;

#pragma mark Colors

static NSInteger const kBaseTextColor = 0x565656;

static NSInteger const kLastModGlyphBackgroundColor = 0x565656;
static NSInteger const kLastModGlyphForgroundColor  = 0xffffff;
static NSInteger const kLastModTimestampColor       = 0x565656;
static NSInteger const kLastModUsernameColor        = 0x565656;

#pragma mark Glyph icon

static CGFloat const kGlyphIconBaselineOffset = 1.6f;

#pragma mark Private properties

@interface WMFOptionsFooterViewController ()

@property (nonatomic, weak) IBOutlet WikiGlyphLabel* lastModGlyphLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel* lastModLabel;

@end

@implementation WMFOptionsFooterViewController

#pragma mark Setup / view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self adjustConstraintsScaleForViews:@[self.lastModGlyphLabel, self.lastModLabel]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // must be done after layout to ensure the view's width is correct before rounding. using viewDidAppear since the
    // button shouldn't be resizing in response to rotation
    [self roundGlyphButtonCorners];
}

#pragma mark Style

- (void)roundGlyphButtonCorners {
    [self.lastModGlyphLabel wmf_makeCircular];
    self.lastModGlyphLabel.clipsToBounds = YES;
}

- (NSDictionary*)getOptionTextBaseAttributes {
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = kOptionTextLineSpacing * MENUS_SCALE_MULTIPLIER;
    return @{
               NSFontAttributeName: [UIFont systemFontOfSize:kOptionTextFontSize * MENUS_SCALE_MULTIPLIER],
               NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kBaseTextColor alpha:1.0],
               NSParagraphStyleAttributeName: paragraphStyle
    };
}

- (NSDictionary*)getSubstitutionTextAttributesWithColor:(NSInteger)hexColor {
    return @{
               NSFontAttributeName: [UIFont systemFontOfSize:kOptionTextFontSize * MENUS_SCALE_MULTIPLIER],
               NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:hexColor alpha:1.0]
    };
}

#pragma mark Last modified option

- (void)updateLastModifiedDate:(NSDate*)date userName:(NSString*)userName {
    self.lastModLabel.attributedText = [self getAttributedStringForOptionLastModifiedByUserName:userName date:date];

    self.lastModGlyphLabel.backgroundColor = [UIColor wmf_colorWithHex:kLastModGlyphBackgroundColor alpha:1.0];
    [self.lastModGlyphLabel setWikiText:WIKIGLYPH_PENCIL
                                  color:[UIColor wmf_colorWithHex:kLastModGlyphForgroundColor alpha:1.0]
                                   size:kGlyphButtonFontSize * MENUS_SCALE_MULTIPLIER
                         baselineOffset:kGlyphIconBaselineOffset];
}

- (NSAttributedString*)getAttributedStringForOptionLastModifiedByUserName:(NSString*)userName date:(NSDate*)date {
    NSString* relativeTimeStamp = [WikipediaAppUtils relativeTimestamp:date];
    NSString* lastModString     = userName ?
                                  MWCurrentArticleLanguageLocalizedString(@"lastmodified-by-user", nil)
                                  : MWCurrentArticleLanguageLocalizedString(@"lastmodified-by-anon", nil);
    return [lastModString
            attributedStringWithAttributes:[self getOptionTextBaseAttributes]
                       substitutionStrings:@[relativeTimeStamp, (userName ? userName : @"")]
                    substitutionAttributes:@[[self getSubstitutionTextAttributesWithColor:kLastModTimestampColor],
                                             [self getSubstitutionTextAttributesWithColor:kLastModUsernameColor]]];
}

#pragma mark Tap gesture handling

- (IBAction)historyOptionTapped:(id)sender {
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:[PageHistoryViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:nc animated:YES completion:nil];
}

@end
