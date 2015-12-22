//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSettingsViewController.h"

// Views
#import "TabularScrollView.h"
#import "SecondaryMenuRowView.h"
#import "PaddedLabel.h"

// View Controllers
#import "LanguagesViewController.h"
#import "LoginViewController.h"
#import "AboutViewController.h"

// Models
#import "MWKSite.h"
#import "MWKLanguageLink.h"

// Networking
#import "QueuesSingleton.h"
#import "SessionSingleton.h"

// Constants
#import "WikiGlyph_Chars.h"
#import "Defines.h"
#import "UIFont+WMFStyle.h"

// Utils
#import "WikipediaAppUtils.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "NSString+FormattedAttributedString.h"
#import "NSBundle+WMFInfoUtils.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIView+WMFRTLMirroring.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLanguageLinkController.h"

// Frameworks
#import <HockeySDK/HockeySDK.h>

// Other
#import "UIViewController+WMFOpenExternalUrl.h"
#import "Wikipedia-Swift.h"

#pragma mark - Defines

#define MENU_ICON_COLOR [UIColor blackColor]
#define MENU_ICON_FONT_SIZE (24.0 * MENUS_SCALE_MULTIPLIER)

#define MENU_TITLE_FONT_SIZE (17.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_SUB_TITLE_FONT_SIZE (15.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_SUB_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.5f alpha:1.0f]

#define URL_ZERO_FAQ @"https://m.wikimediafoundation.org/wiki/Wikipedia_Zero_App_FAQ"
#define URL_TERMS @"https://m.wikimediafoundation.org/wiki/Terms_of_Use"
#define URL_RATE_APP @"itms-apps://itunes.apple.com/app/id324715238"

typedef NS_ENUM (NSUInteger, SecondaryMenuRowIndex) {
    SECONDARY_MENU_ROW_INDEX_LOGIN,
    SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE,
    SECONDARY_MENU_ROW_INDEX_ZERO_FAQ,
    SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING,
    SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK,
    SECONDARY_MENU_ROW_INDEX_ABOUT,
    SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS,
    SECONDARY_MENU_ROW_INDEX_PRIVACY_POLICY,
    SECONDARY_MENU_ROW_INDEX_TERMS,
    SECONDARY_MENU_ROW_INDEX_RATE_APP,
    SECONDARY_MENU_ROW_INDEX_DEBUG_CRASH,
    SECONDARY_MENU_ROW_INDEX_HEADING_ZERO,
    SECONDARY_MENU_ROW_INDEX_HEADING_ABOUT,
    SECONDARY_MENU_ROW_INDEX_HEADING_LEGAL,
    SECONDARY_MENU_ROW_INDEX_HEADING_DEBUG,
    SECONDARY_MENU_ROW_INDEX_HEADING_BLANK,
    SECONDARY_MENU_ROW_INDEX_HEADING_BLANK_2,
    SECONDARY_MENU_ROW_INDEX_FAQ
};

static uint const WMFDebugSectionCount                                    = 2;
static SecondaryMenuRowIndex const WMFDebugSections[WMFDebugSectionCount] = {
    SECONDARY_MENU_ROW_INDEX_DEBUG_CRASH,
    SECONDARY_MENU_ROW_INDEX_HEADING_DEBUG
};

#pragma mark - Private

@interface WMFSettingsViewController () <LanguageSelectionDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet TabularScrollView* scrollView;
@property (strong, nonatomic) NSMutableArray* rowData;
@property (strong, nonatomic) NSMutableArray* rowViews;
@property (strong, nonatomic) NSDictionary* highlightedTextAttributes;

@end

@implementation WMFSettingsViewController

- (NSString*)title {
    return MWLocalizedString(@"settings-title", nil);
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];

    @weakify(self)
    UIBarButtonItem * xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItems = @[xButton];

    self.highlightedTextAttributes = @{ NSFontAttributeName: [UIFont italicSystemFontOfSize:MENU_TITLE_FONT_SIZE] };

    self.view.backgroundColor = [UIColor wmf_settingsBackgroundColor];

    self.scrollView.clipsToBounds    = NO;
    self.scrollView.minSubviewHeight = 45;

    self.rowViews = @[].mutableCopy;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.rowViews removeAllObjects];

    [self loadRowViews];

    self.scrollView.orientation     = TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL;
    self.scrollView.tabularSubviews = self.rowViews;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tabularScrollViewItemTappedNotification:)
                                                 name:@"TabularScrollViewItemTapped"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"TabularScrollViewItemTapped"
                                                  object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - Access

- (SecondaryMenuRowIndex)getIndexOfRow:(NSDictionary*)row {
    return (SecondaryMenuRowIndex)((NSNumber*)row[@"tag"]).integerValue;
}

- (SecondaryMenuRowView*)getViewWithTag:(SecondaryMenuRowIndex)tag {
    for (SecondaryMenuRowView* view in self.rowViews) {
        if (view.tag == tag) {
            return view;
        }
    }
    return nil;
}

- (NSMutableDictionary*)getRowWithTag:(SecondaryMenuRowIndex)tag {
    for (NSMutableDictionary* row in self.rowData) {
        SecondaryMenuRowIndex index = [self getIndexOfRow:row];
        if (tag == index) {
            return row;
        }
    }
    return nil;
}

#pragma mark - Rows

- (void)deleteRowWithTag:(SecondaryMenuRowIndex)tag {
    NSMutableDictionary* rowToDelete = [self getRowWithTag:tag];
    if (rowToDelete) {
        [self.rowData removeObject:rowToDelete];
    }
}

- (void)loadRowViews {
    [self setRowData];

    for (NSUInteger i = 0; i < self.rowData.count; i++) {
        NSMutableDictionary* row = self.rowData[i];

        // Don't forget - had to select "File's Owner" in left column of xib and then choose
        // this view controller in the Identity Inspector (3rd icon from left in right column)
        // in the Custom Class / Class dropdown. See: http://stackoverflow.com/a/21991592
        SecondaryMenuRowView* rowView =
            [[[SecondaryMenuRowView wmf_classNib] instantiateWithOwner:self options:nil] firstObject];

        rowView.tag              = [self getIndexOfRow:row];
        rowView.optionSwitch.tag = rowView.tag;

        rowView.optionSwitch.tintColor   = [UIColor colorWithWhite:0.88 alpha:1.0];
        rowView.optionSwitch.onTintColor = [UIColor blackColor];

        switch (rowView.tag) {
            case SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING:
                rowView.optionSwitch.hidden = NO;
                [rowView.optionSwitch setOn:[SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving];
                break;

            case SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS:
                rowView.optionSwitch.hidden = NO;
                [rowView.optionSwitch setOn:[SessionSingleton sharedInstance].shouldSendUsageReports];
                break;

            default:
                break;
        }

        [rowView.optionSwitch addTarget:self
                                 action:@selector(switchTapped:)
                       forControlEvents:UIControlEventValueChanged];

        [self.rowViews addObject:rowView];
    }

    [self updateLoginRow];
    [self applyRowSettings];
}

- (void)switchTapped:(UISwitch*)sender {
    //NSLog(@"switch %d tapped isOn %d", sender.tag, sender.isOn);
    switch (sender.tag) {
        case SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING:
            [[SessionSingleton sharedInstance].zeroConfigState toggleWarnWhenLeaving];
            break;

        case SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS:
            [SessionSingleton sharedInstance].shouldSendUsageReports = sender.isOn;
            break;

        default:
            break;
    }
}

- (void)applyRowSettings {
    for (NSUInteger i = 0; i < self.rowData.count; i++) {
        NSMutableDictionary* row      = self.rowData[i];
        SecondaryMenuRowIndex index   = [self getIndexOfRow:row];
        SecondaryMenuRowView* rowView = [self getViewWithTag:index];

        NSDictionary* attributes =
            @{
            NSFontAttributeName: [UIFont wmf_glyphFontOfSize:MENU_ICON_FONT_SIZE],
            NSForegroundColorAttributeName: MENU_ICON_COLOR,
            NSBaselineOffsetAttributeName: @2
        };

        NSString* icon = row[@"icon"];
        rowView.iconLabel.attributedText =
            [[NSAttributedString alloc] initWithString:icon
                                            attributes:attributes];

        id title = row[@"title"];
        if ([title isKindOfClass:[NSString class]]) {
            //title = [NSString stringWithFormat:@"%@ %@ %@", title, title, title];
            rowView.textLabel.text = title;
        } else if ([title isKindOfClass:[NSAttributedString class]]) {
            rowView.textLabel.attributedText = title;
        }

        NSNumber* rowType = row[@"type"];
        rowView.rowType = rowType.integerValue;

        NSNumber* traits = row[@"accessibilityTraits"];
        if (traits) {
            rowView.textLabel.accessibilityTraits = traits.integerValue;
        }
    }

    // Let the rows know their relative positions so they can draw
    // borders appropriately.
    RowType lastRowType = ROW_TYPE_UNKNOWN;
    for (SecondaryMenuRowView* view in self.rowViews) {
        view.rowPosition = (view.rowType != lastRowType) ? ROW_POSITION_TOP : ROW_POSITION_UNKNOWN;
        lastRowType      = view.rowType;
    }
}

- (void)setRowData {
    //NSString *ltrSafeCaretCharacter = [WikipediaAppUtils isDeviceLanguageRTL] ? WIKIGLYPH_BACKWARD : WIKIGLYPH_FORWARD;


    //NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;

    NSString* languageCode = [SessionSingleton sharedInstance].searchSite.language;
    NSString* languageName = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:languageCode];
    if (!languageName) {
        languageName = [WikipediaAppUtils languageNameForCode:languageCode];
    }
    NSAttributedString* searchWikiTitle =
        [MWLocalizedString(@"main-menu-language-title", nil) attributedStringWithAttributes:nil
                                                                        substitutionStrings:@[languageName]
                                                                     substitutionAttributes:@[self.highlightedTextAttributes]
        ];

    NSString* sendUsageBase =
        [MWLocalizedString(@"preference_title_eventlogging_opt_in", nil) stringByAppendingString:@"\n$1"];

    NSString* sendUsageSummary =
        MWLocalizedString(@"preference_summary_eventlogging_opt_in", nil);

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 5;
    //paragraphStyle.lineSpacing = 8;

    NSDictionary* summaryTextAttributes =
        @{
        NSFontAttributeName: [UIFont systemFontOfSize:MENU_SUB_TITLE_FONT_SIZE],
        NSForegroundColorAttributeName: MENU_SUB_TITLE_TEXT_COLOR,
        NSParagraphStyleAttributeName: paragraphStyle
    };

    NSAttributedString* sendUsageDataTitle =
        [sendUsageBase attributedStringWithAttributes:nil
                                  substitutionStrings:@[sendUsageSummary]
                               substitutionAttributes:@[summaryTextAttributes]];

    NSMutableArray* rowData =
        @[
        @{
            @"domain": languageCode,
            @"title": searchWikiTitle,
            @"tag": @(SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE),
            @"icon": WIKIGLYPH_DOWN,
            @"type": @(ROW_TYPE_SELECTION),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-heading-about", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_HEADING_ABOUT),
            @"icon": @"",
            @"type": @(ROW_TYPE_HEADING),
        }.mutableCopy
        ,
        @{
            @"domain": [SessionSingleton sharedInstance].searchSite.language,
            @"title": MWLocalizedString(@"main-menu-about", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_ABOUT),
            @"icon": WIKIGLYPH_DOWN,
            @"type": @(ROW_TYPE_SELECTION),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-faq", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_FAQ),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink)
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-heading-legal", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_HEADING_LEGAL),
            @"icon": @"",
            @"type": @(ROW_TYPE_HEADING),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-privacy-policy", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_PRIVACY_POLICY),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-terms-of-use", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_TERMS),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
        ,
        @{
            @"title": sendUsageDataTitle,
            @"tag": @(SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-heading-zero", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_HEADING_ZERO),
            @"icon": @"",
            @"type": @(ROW_TYPE_HEADING),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-zero-faq", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_ZERO_FAQ),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"zero-warn-when-leaving", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
        }.mutableCopy
        ,
        @{
            @"title": @"",
            @"tag": @(SECONDARY_MENU_ROW_INDEX_HEADING_BLANK),
            @"icon": @"",
            @"type": @(ROW_TYPE_HEADING),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-rate-app", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_RATE_APP),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
        ,
        @{
            @"title": @"",
            @"tag": @(SECONDARY_MENU_ROW_INDEX_LOGIN),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
        }.mutableCopy
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-heading-debug", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_HEADING_DEBUG),
            @"icon": @"",
            @"type": @(ROW_TYPE_HEADING),
            @"accessibilityTraits": @(UIAccessibilityTraitLink)
        }
        ,
        @{
            @"title": MWLocalizedString(@"main-menu-debug-crash", nil),
            @"tag": @(SECONDARY_MENU_ROW_INDEX_DEBUG_CRASH),
            @"icon": @"",
            @"type": @(ROW_TYPE_SELECTION),
            @"accessibilityTraits": @(UIAccessibilityTraitLink),
        }.mutableCopy
    ].mutableCopy;

    self.rowData = rowData;

    if (![[NSBundle mainBundle] wmf_shouldShowDebugMenu]) {
        for (int i = 0; i < WMFDebugSectionCount; i++) {
            [self deleteRowWithTag:WMFDebugSections[i]];
        }
    }
}

- (void)updateLoginRow {
    id loginTitle       = nil;
    NSString* loginIcon = @"";
    NSString* userName  = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if (userName) {
        loginTitle = [MWLocalizedString(@"main-menu-account-logout", nil) stringByAppendingString:@" $1"];

        loginTitle =
            [loginTitle attributedStringWithAttributes:nil
                                   substitutionStrings:@[userName]
                                substitutionAttributes:@[self.highlightedTextAttributes]
            ];

        //loginIcon = WIKIGLYPH_USER_SMILE;
    } else {
        loginTitle = MWLocalizedString(@"main-menu-account-login", nil);
        //loginIcon = WIKIGLYPH_USER_SLEEP;
    }

    NSMutableDictionary* row = [self getRowWithTag:SECONDARY_MENU_ROW_INDEX_LOGIN];
    row[@"title"] = loginTitle;
    row[@"icon"]  = loginIcon;
}

#pragma mark - Selection

- (void)tabularScrollViewItemTappedNotification:(NSNotification*)notification {
    CGFloat animationDuration        = 0.08f;
    NSDictionary* userInfo           = [notification userInfo];
    SecondaryMenuRowView* tappedItem = userInfo[@"tappedItem"];

    DDLogInfo(@"Tapped settings item: %@", tappedItem.textLabel.text);

    if (tappedItem.tag == SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING
        || tappedItem.tag == SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS) {
        animationDuration = 0.0f;
    }

    void (^ performTapAction)() = ^() {
        switch (tappedItem.tag) {
            case SECONDARY_MENU_ROW_INDEX_LOGIN:
            {
                NSString* userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
                if (userName) {
                    [SessionSingleton sharedInstance].keychainCredentials.userName   = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.password   = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.editTokens = nil;

                    // Clear session cookies too.
                    for (NSHTTPCookie* cookie in[[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
                    }
                } else {
                    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[LoginViewController wmf_initialViewControllerFromClassStoryboard]] animated:YES completion:nil];
                }
            }
            break;

            case SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE:
                [self showLanguages];
                break;

            case SECONDARY_MENU_ROW_INDEX_ZERO_FAQ:
            {
                [self wmf_openExternalUrl:[NSURL URLWithString:URL_ZERO_FAQ]];
            }
            break;

            case SECONDARY_MENU_ROW_INDEX_PRIVACY_POLICY:
            {
                [self wmf_openExternalUrl:[NSURL URLWithString:URL_PRIVACY_POLICY]];
            }
            break;

            case SECONDARY_MENU_ROW_INDEX_TERMS:
            {
                [self wmf_openExternalUrl:[NSURL URLWithString:URL_TERMS]];
            }
            break;

            case SECONDARY_MENU_ROW_INDEX_RATE_APP:
            {
                [self wmf_openExternalUrl:[NSURL URLWithString:URL_RATE_APP]];
            }
            break;

            case SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING:
                // Don't do anything here - only take action for this if the toggle tapped.
                break;

            case SECONDARY_MENU_ROW_INDEX_SEND_USAGE_REPORTS:
                // Don't do anything here - only take action for this if the toggle tapped.
                break;

            case SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK:
            {
                NSString* mailtoUri =
                    [NSString stringWithFormat:@"mailto:mobile-ios-wikipedia@wikimedia.org?subject=Feedback:%@", [WikipediaAppUtils versionedUserAgent]];

                NSString* encodedUrlString =
                    [mailtoUri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                NSURL* url = [NSURL URLWithString:encodedUrlString];

                [self wmf_openExternalUrl:url];
            }
            break;
            case SECONDARY_MENU_ROW_INDEX_ABOUT:
            {
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[AboutViewController wmf_initialViewControllerFromClassStoryboard]] animated:YES completion:nil];
            }
            break;
            case SECONDARY_MENU_ROW_INDEX_DEBUG_CRASH: {
                [[self class] generateTestCrash];
                break;
            }
            case SECONDARY_MENU_ROW_INDEX_FAQ: {
                [self wmf_openExternalUrl:
                 [NSURL URLWithString:@"https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"]];
                break;
            }
            default:
                break;
        }

        [self loadRowViews];
    };

    CGFloat animationScale = 1.28f;

    NSMutableDictionary* row = [self getRowWithTag:(SecondaryMenuRowIndex)tappedItem.tag];

    NSString* icon = [row objectForKey:@"icon"];

    if (icon && (icon.length > 0) && (animationDuration > 0)) {
        [tappedItem.iconLabel animateAndRewindXF:CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                                      afterDelay:0.0
                                        duration:animationDuration
                                            then:performTapAction
        ];
    } else {
        performTapAction();
    }
}

+ (void)generateTestCrash {
    if ([[BITHockeyManager sharedHockeyManager] crashManager]) {
        DDLogWarn(@"Generating test crash!");
        __builtin_trap();
    } else {
        DDLogError(@"Crash manager was not setup!");
    }
}

- (void)showLanguages {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:nil];
}

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[SessionSingleton sharedInstance] setSearchLanguage:language.languageCode];
    [[MWKLanguageLinkController sharedInstance] addPreferredLanguage:language];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Animation

- (UILabel*)getLabelCopyToAnimate:(UILabel*)labelToCopy {
    UILabel* labelCopy = [[UILabel alloc] init];
    CGRect sourceRect  = [labelToCopy convertRect:labelToCopy.bounds toView:self.view];
    labelCopy.frame           = sourceRect;
    labelCopy.text            = labelToCopy.text;
    labelCopy.font            = labelToCopy.font;
    labelCopy.textColor       = [UIColor colorWithWhite:0.3 alpha:1.0];
    labelCopy.backgroundColor = [UIColor clearColor];
    labelCopy.textAlignment   = labelToCopy.textAlignment;
    labelCopy.lineBreakMode   = labelToCopy.lineBreakMode;
    labelCopy.numberOfLines   = labelToCopy.numberOfLines;
    [self.view addSubview:labelCopy];
    return labelCopy;
}

- (CGPoint)getLocationForView:(UIView*)view xf:(CGAffineTransform)xf {
    CGPoint point       = [view convertPoint:view.center toView:self.view];
    CGPoint scaledPoint = [view convertPoint:CGPointApplyAffineTransform(view.center, xf) toView:self.view];
    scaledPoint.y = point.y;
    return scaledPoint;
}

- (void)animateView:(UIView*)view
      toDestination:(CGPoint)destPoint
         afterDelay:(CGFloat)delay
           duration:(CGFloat)duration
          transform:(CGAffineTransform)xf {
    [UIView animateWithDuration:duration
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        view.center = destPoint;
        view.alpha = 0.3f;
        view.transform = xf;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Scroll

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    [self wmf_hideKeyboard];
}

/*
   -(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
   {
    self.scrollView.orientation = !self.scrollView.orientation;
   }
 */

@end
