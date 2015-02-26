//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "OptionsFooterViewController.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "MWLanguageInfo.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyphLabel.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "NSString+FormattedAttributedString.h"
#import "UIColor+WMFHexColor.h"
#import "UIViewController+ModalPresent.h"
#import "LanguagesViewController.h"

#pragma mark Font sizes

static const CGFloat kGlyphButtonFontSize = 23.0f;
static const CGFloat kOptionTextFontSize = 15.0f;
static const CGFloat kOptionTextLineSpacing = 2.0f;

#pragma mark Colors

static const NSInteger kBaseTextColor = 0x565656;

static const NSInteger kLastModGlyphBackgroundColor = 0x565656;
static const NSInteger kLastModGlyphForgroundColor = 0xffffff;
static const NSInteger kLastModTimestampColor = 0x565656;
static const NSInteger kLastModUsernameColor = 0x565656;

static const NSInteger kLangGlyphBackgroundColor = 0x565656;
static const NSInteger kLangGlyphForgroundColor = 0xffffff;
static const NSInteger kLangCountColor = 0x565656;

#pragma mark Private properties

@interface OptionsFooterViewController () <LanguageSelectionDelegate>

@property (nonatomic, weak) IBOutlet WikiGlyphLabel *langGlyphLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel *langLabel;

@property (nonatomic, weak) IBOutlet WikiGlyphLabel *lastModGlyphLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel *lastModLabel;

@end

@implementation OptionsFooterViewController

#pragma mark Setup / view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self roundGlyphButtonCorners];
    
    [self adjustConstraintsScaleForViews:
        @[self.langGlyphLabel, self.langLabel, self.lastModGlyphLabel, self.lastModLabel]];
}

#pragma mark Style

-(void)roundGlyphButtonCorners
{
    self.langGlyphLabel.layer.cornerRadius = self.langGlyphLabel.frame.size.width / 2.0f;
    self.lastModGlyphLabel.layer.cornerRadius = self.langGlyphLabel.frame.size.width / 2.0f;
    self.langGlyphLabel.clipsToBounds = YES;
    self.lastModGlyphLabel.clipsToBounds = YES;
}

-(NSDictionary *)getOptionTextBaseAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = kOptionTextLineSpacing * MENUS_SCALE_MULTIPLIER;
    return @{
             NSFontAttributeName : [UIFont systemFontOfSize:kOptionTextFontSize],
             NSForegroundColorAttributeName : [UIColor wmf_colorWithHex:kBaseTextColor alpha:1.0],
             NSParagraphStyleAttributeName : paragraphStyle
             };
}

#pragma mark Language option

-(void)updateLanguageCount:(NSInteger)count
{
    self.langGlyphLabel.backgroundColor = [UIColor wmf_colorWithHex:kLangGlyphBackgroundColor alpha:1.0];

    [self.langGlyphLabel setWikiText: WIKIGLYPH_TRANSLATE
                               color: [UIColor wmf_colorWithHex:kLangGlyphForgroundColor alpha:1.0]
                                size: kGlyphButtonFontSize * MENUS_SCALE_MULTIPLIER
                      baselineOffset: 1.7];

    self.langLabel.attributedText = [self getAttributedStringForOptionLanguagesWithCount:count];
}

-(NSAttributedString *)getAttributedStringForOptionLanguagesWithCount:(NSInteger)count
{
    NSString *langButtonString = [MWLocalizedString(@"language-button-text", nil) stringByReplacingOccurrencesOfString:@"%d" withString:@"$1"];
    
    return
    [langButtonString attributedStringWithAttributes: [self getOptionTextBaseAttributes]
                  substitutionStrings: @[[NSString stringWithFormat:@"%ld", (long)count]]
               substitutionAttributes: @[@{NSForegroundColorAttributeName : [UIColor wmf_colorWithHex:kLangCountColor alpha:1.0]}]];
}

#pragma mark Last modified option

-(void)updateLastModifiedDate:(NSDate *)date userName:(NSString *)userName
{
    self.lastModLabel.attributedText = [self getAttributedStringForOptionLastModifiedByUserName:userName date:date];

    self.lastModGlyphLabel.backgroundColor = [UIColor wmf_colorWithHex:kLastModGlyphBackgroundColor alpha:1.0];
    [self.lastModGlyphLabel setWikiText: WIKIGLYPH_PENCIL
                                  color: [UIColor wmf_colorWithHex:kLastModGlyphForgroundColor alpha:1.0]
                                   size: kGlyphButtonFontSize * MENUS_SCALE_MULTIPLIER
                         baselineOffset: 1.7];
}

-(NSAttributedString *)getAttributedStringForOptionLastModifiedByUserName:(NSString *)userName date:(NSDate *)date
{
    NSString *relativeTimeStamp = [WikipediaAppUtils relativeTimestamp:date];
    NSString *lastModString = userName ? MWLocalizedString(@"lastmodified-by-user", nil) : MWLocalizedString(@"lastmodified-by-anon", nil);

    return
    [lastModString attributedStringWithAttributes: [self getOptionTextBaseAttributes]
                              substitutionStrings: @[relativeTimeStamp, (userName ? userName : @"")]
                           substitutionAttributes: @[
                                                     @{NSForegroundColorAttributeName : [UIColor wmf_colorWithHex:kLastModTimestampColor alpha:1.0]},
                                                     @{NSForegroundColorAttributeName : [UIColor wmf_colorWithHex:kLastModUsernameColor alpha:1.0]}
                                                     ]];
}

#pragma mark Tap gesture handling

-(IBAction)historyOptionTapped:(id)sender
{
    [self performModalSequeWithID: @"modal_segue_show_page_history"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: nil];
}

-(IBAction)languagesOptionTapped:(id)sender
{
    [self performModalSequeWithID: @"modal_segue_show_languages"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: ^(LanguagesViewController *languagesVC){
                                languagesVC.downloadLanguagesForCurrentArticle = YES;
                                languagesVC.invokingVC = self;
                                languagesVC.languageSelectionDelegate = self;
                            }];
}

#pragma mark LanguageSelectionDelegate

- (void)languageSelected:(NSDictionary *)langData sender:(LanguagesViewController *)sender
{
    MWKSite *site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:langData[@"code"]];
    MWKTitle *title = [site titleWithString:langData[@"*"]];
    [NAV loadArticleWithTitle: title
                     animated: NO
              discoveryMethod: MWK_DISCOVERY_METHOD_SEARCH
                   popToWebVC: YES];

    [self dismissLanguagePicker];
}

-(void)dismissLanguagePicker
{
    [self.presentedViewController dismissViewControllerAnimated: YES
                                                     completion: ^{}];
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
