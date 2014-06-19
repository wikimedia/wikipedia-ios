//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SecondaryMenuViewController.h"
#import "LoginViewController.h"
#import "HistoryViewController.h"
#import "SavedPagesViewController.h"
#import "QueuesSingleton.h"
#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "LanguagesTableVC.h"

#import "UIViewController+HideKeyboard.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "UIViewController+Alert.h"
#import "NSString+FormattedAttributedString.h"
#import "TabularScrollView.h"

#import "SecondaryMenuRowView.h"

#import "WikiGlyph_Chars.h"

#import "TopMenuContainerView.h"
#import "TopMenuViewController.h"
#import "UIViewController+StatusBarHeight.h"

#import "Defines.h"
#import "ModalMenuAndContentViewController.h"
#import "UIViewController+PresentModal.h"

#pragma mark - Defines

#define BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:1.0f]
#define MENU_ICON_COLOR [UIColor blackColor]
#define MENU_ICON_COLOR_DESELECTED [UIColor lightGrayColor];
#define MENU_ICON_FONT_SIZE 38

typedef enum {
    SECONDARY_MENU_ROW_INDEX_LOGIN = 0,
    SECONDARY_MENU_ROW_INDEX_SAVED_PAGES = 3,
    SECONDARY_MENU_ROW_INDEX_SAVE_PAGE = 4,
    SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE = 5,
    SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING = 6,
    SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK = 7,
    SECONDARY_MENU_ROW_INDEX_PAGE_HISTORY = 8,
    SECONDARY_MENU_ROW_INDEX_CREDITS = 9
} SecondaryMenuRowIndex;

#pragma mark - Private

@interface SecondaryMenuViewController(){

}

@property (strong, nonatomic) IBOutlet TabularScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *rowData;
@property (strong, nonatomic) NSMutableArray *rowViews;
@property (nonatomic) BOOL hidePagesSection;

@property (strong, nonatomic) NSDictionary *highlightedTextAttributes;

@end

@implementation SecondaryMenuViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.title = MWLocalizedString(@"main-menu-title", nil);
        self.navBarMode = NAVBAR_MODE_X_WITH_LABEL;
    }
    return self;
}

#pragma mark - Top menu

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self hide];

            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Hiding

-(void)hide
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

-(void)hidePresenter
{
    // Hide the black menu which presented this view controller.
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated: YES
                                                                               completion: ^{}];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.highlightedTextAttributes = @{NSFontAttributeName: [UIFont italicSystemFontOfSize:16]};

    self.hidePagesSection = NO;
    self.navigationItem.hidesBackButton = YES;

    self.view.backgroundColor = BACKGROUND_COLOR;
    
    self.scrollView.clipsToBounds = NO;
    
    self.rowViews = @[].mutableCopy;
    
    // This needs to be in viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                         selector: @selector(languageItemSelectedNotification:)
                                             name: @"LanguageItemSelected"
                                           object: nil];
}

-(void)dealloc
{
    // This needs to be in dealloc.
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"LanguageItemSelected"
                                                  object: nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;

    self.hidePagesSection =
        (!currentArticleTitle || (currentArticleTitle.length == 0)) ? YES : NO;
    
    [self.rowViews removeAllObjects];

    [self loadRowViews];
    
    self.scrollView.orientation = TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL;
    self.scrollView.tabularSubviews = self.rowViews;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(tabularScrollViewItemTappedNotification:)
                                                 name: @"TabularScrollViewItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"TabularScrollViewItemTapped"
                                                  object: nil];
    [super viewWillDisappear:animated];
}

#pragma mark - Access

-(SecondaryMenuRowIndex)getIndexOfRow:(NSDictionary *)row
{
    return ((NSNumber *)row[@"tag"]).integerValue;
}

-(SecondaryMenuRowView *)getViewWithTag:(SecondaryMenuRowIndex)tag
{
    for (SecondaryMenuRowView *view in self.rowViews) {
        if(view.tag== tag) return view;
    }
    return nil;
}

-(NSMutableDictionary *)getRowWithTag:(SecondaryMenuRowIndex)tag
{
    for (NSMutableDictionary *row in self.rowData) {
        SecondaryMenuRowIndex index = [self getIndexOfRow:row];
        if (tag == index) return row;
    }
    return nil;
}

#pragma mark - Rows

-(void)deleteRowWithTag:(SecondaryMenuRowIndex)tag
{
    NSMutableDictionary *rowToDelete = [self getRowWithTag:tag];
    if (rowToDelete) [self.rowData removeObject:rowToDelete];
}

-(void)loadRowViews
{
    // Don't forget - had to select "File's Owner" in left column of xib and then choose
    // this view controller in the Identity Inspector (3rd icon from left in right column)
    // in the Custom Class / Class dropdown. See: http://stackoverflow.com/a/21991592
    UINib *secondaryMenuRowViewNib = [UINib nibWithNibName:@"SecondaryMenuRowView" bundle:nil];

    [self setRowData];

    for (NSUInteger i = 0; i < self.rowData.count; i++) {
        NSMutableDictionary *row = self.rowData[i];

        SecondaryMenuRowView *rowView = [[secondaryMenuRowViewNib instantiateWithOwner:self options:nil] firstObject];

        rowView.tag = [self getIndexOfRow:row];

        [self.rowViews addObject:rowView];
    }

    [self updateLoginRow];
    [self applyRowSettings];
}

-(void)applyRowSettings
{
    for (NSUInteger i = 0; i < self.rowData.count; i++) {

        NSMutableDictionary *row = self.rowData[i];
        SecondaryMenuRowIndex index = [self getIndexOfRow:row];
        SecondaryMenuRowView *rowView = [self getViewWithTag:index];

        rowView.highlighted = ((NSNumber *)row[@"highlighted"]).boolValue;

        UIColor *iconColor = rowView.highlighted ? MENU_ICON_COLOR : MENU_ICON_COLOR_DESELECTED;

        NSDictionary *attributes =
            @{
              NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:MENU_ICON_FONT_SIZE],
              NSForegroundColorAttributeName : iconColor,
              NSBaselineOffsetAttributeName: @2
              };

        rowView.iconLabel.attributedText =
            [[NSAttributedString alloc] initWithString: row[@"icon"]
                                            attributes: attributes];

        id title = row[@"title"];
        if([title isKindOfClass:[NSString class]]){
            rowView.textLabel.text = title;
        }else if([title isKindOfClass:[NSAttributedString class]]){
            rowView.textLabel.attributedText = title;
        }
    }
}

-(void)setRowData
{
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    
    NSAttributedString *searchWikiTitle =
    [MWLocalizedString(@"main-menu-language-title", nil) attributedStringWithAttributes: nil
                                                                    substitutionStrings: @[[SessionSingleton sharedInstance].domainName]
                                                                 substitutionAttributes: @[self.highlightedTextAttributes]
     ];
    
    /*
    NSAttributedString *saveArticleTitle =
    [MWLocalizedString(@"main-menu-current-article-save", nil) attributedStringWithAttributes: nil
                                                                          substitutionStrings: @[currentArticleTitle]
                                                                       substitutionAttributes: @[self.highlightedTextAttributes]
     ];
     */

    NSAttributedString *pageHistoryTitle =
    [MWLocalizedString(@"main-menu-show-page-history", nil) attributedStringWithAttributes: nil
                                                                       substitutionStrings: @[currentArticleTitle]
                                                                    substitutionAttributes: @[self.highlightedTextAttributes]
     ];
    
    NSMutableArray *rowData =
    @[
      @{
          @"title": @"",
          @"tag": @(SECONDARY_MENU_ROW_INDEX_LOGIN),
          @"icon": WIKIGLYPH_USER_SLEEP,
          @"highlighted": @YES,
          }.mutableCopy
      ,
      /*
      @{
          @"title": MWLocalizedString(@"main-menu-show-saved", nil),
          @"tag": @(SECONDARY_MENU_ROW_INDEX_SAVED_PAGES),
          @"icon": WIKIGLYPH_BOOKMARK,
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": saveArticleTitle,
          @"tag": @(SECONDARY_MENU_ROW_INDEX_SAVE_PAGE),
          @"icon": WIKIGLYPH_DOWNLOAD,
          @"highlighted": @YES,
          }.mutableCopy
      ,
      */
      @{
          @"domain": [SessionSingleton sharedInstance].domain,
          @"title": searchWikiTitle,
          @"tag": @(SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE),
          @"icon": WIKIGLYPH_TRANSLATE,
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": pageHistoryTitle,
          @"tag": @(SECONDARY_MENU_ROW_INDEX_PAGE_HISTORY),
          @"icon": WIKIGLYPH_LINK,
          @"highlighted": @YES,
          }.mutableCopy
        ,
      @{
          @"domain": [SessionSingleton sharedInstance].domain,
          @"title": MWLocalizedString(@"main-menu-credits", nil),
          @"tag": @(SECONDARY_MENU_ROW_INDEX_CREDITS),
          @"icon": WIKIGLYPH_PUZZLE,
          @"highlighted": @YES,
          }.mutableCopy
        ,
      @{
          @"title": MWLocalizedString(@"main-menu-send-feedback", nil),
          @"tag": @(SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK),
          @"icon": WIKIGLYPH_ENVELOPE,
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"zero-warn-when-leaving", nil),
          @"tag": @(SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING),
          @"icon": WIKIGLYPH_FLAG,
          @"highlighted": @([SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving),
          }.mutableCopy
      ].mutableCopy;

    self.rowData = rowData;
    
    if(self.hidePagesSection){
        [self deleteRowWithTag:SECONDARY_MENU_ROW_INDEX_SAVE_PAGE];
        [self deleteRowWithTag:SECONDARY_MENU_ROW_INDEX_PAGE_HISTORY];
    }
    
    NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if(!userName){
        [self deleteRowWithTag:SECONDARY_MENU_ROW_INDEX_LOGIN];
    }
}

-(void)updateLoginRow
{
    id loginTitle = nil;
    NSString *loginIcon = @"";
    NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if(userName){
        loginTitle = [MWLocalizedString(@"main-menu-account-logout", nil) stringByAppendingString:@" $1"];
        
        loginTitle =
        [loginTitle attributedStringWithAttributes: nil
                               substitutionStrings: @[userName]
                            substitutionAttributes: @[self.highlightedTextAttributes]
         ];
        
        loginIcon = WIKIGLYPH_USER_SMILE;
    }else{
        loginTitle = MWLocalizedString(@"main-menu-account-login", nil);
        loginIcon = WIKIGLYPH_USER_SLEEP;
    }
    
    NSMutableDictionary *row = [self getRowWithTag:SECONDARY_MENU_ROW_INDEX_LOGIN];
    row[@"title"] = loginTitle;
    row[@"icon"] = loginIcon;
}

#pragma mark - Selection

- (void)tabularScrollViewItemTappedNotification:(NSNotification *)notification
{
    CGFloat animationDuration = 0.08f;
    NSDictionary *userInfo = [notification userInfo];
    SecondaryMenuRowView *tappedItem = userInfo[@"tappedItem"];
    
    if (tappedItem.tag == SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING) animationDuration = 0.0f;
    
    void(^performTapAction)() = ^(){
    
        switch (tappedItem.tag) {
            case SECONDARY_MENU_ROW_INDEX_LOGIN:
            {
                NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
                if (!userName) {
                    LoginViewController *loginVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                    loginVC.funnel = [[LoginFunnel alloc] init];
                    [loginVC.funnel logStartFromNavigation];
                    [ROOT pushViewController:loginVC animated:YES];
                }else{
                    
                    [SessionSingleton sharedInstance].keychainCredentials.userName = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.password = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.editTokens = nil;
                    
                    // Clear session cookies too.
                    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
                    }
                }
                [self hidePresenter];
            }
                break;
            case SECONDARY_MENU_ROW_INDEX_SAVED_PAGES:
            {
                SavedPagesViewController *savedPagesVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"SavedPagesViewController"];
                [ROOT pushViewController:savedPagesVC animated:YES];
            }
                break;
            case SECONDARY_MENU_ROW_INDEX_SAVE_PAGE:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
                [self animateArticleTitleMovingToSavedPages];
                break;
            case SECONDARY_MENU_ROW_INDEX_SEARCH_LANGUAGE:
                [self showLanguages];
                break;
            case SECONDARY_MENU_ROW_INDEX_ZERO_WARN_WHEN_LEAVING:
                [[SessionSingleton sharedInstance].zeroConfigState toggleWarnWhenLeaving];
                break;
            case SECONDARY_MENU_ROW_INDEX_SEND_FEEDBACK:
            {
                NSString *mailtoUri =
                [NSString stringWithFormat:@"mailto:mobile-ios-wikipedia@wikimedia.org?subject=Feedback:%@", [WikipediaAppUtils versionedUserAgent]];
                
                NSString *encodedUrlString =
                    [mailtoUri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                NSURL *url = [NSURL URLWithString:encodedUrlString];
                
                [[UIApplication sharedApplication] openURL:url];
            }
                break;
            case SECONDARY_MENU_ROW_INDEX_PAGE_HISTORY:
            {
                [self performModalSequeWithID: @"modal_segue_show_page_history"
                              transitionStyle: UIModalTransitionStyleCoverVertical
                                        block: nil];
            }
                break;
            case SECONDARY_MENU_ROW_INDEX_CREDITS:
            {
                [self performModalSequeWithID: @"modal_segue_show_credits"
                              transitionStyle: UIModalTransitionStyleCoverVertical
                                        block: nil];
            }
                break;
            default:
                break;
        }
        
        [self loadRowViews];
    };

    CGFloat animationScale = 1.28f;
    
    NSMutableDictionary *row = [self getRowWithTag:tappedItem.tag];
    
    NSString *icon = [row objectForKey:@"icon"];
    
    if (icon && (icon.length > 0) && (animationDuration > 0)) {
        [tappedItem.iconLabel animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                                      afterDelay: 0.0
                                        duration: animationDuration
                                            then: performTapAction
         ];
    }else{
        performTapAction();
    }
}

-(void)showLanguages
{
    [self performModalSequeWithID: @"modal_segue_show_languages"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: ^(LanguagesTableVC *languagesTableVC){
                                languagesTableVC.invokingVC = self;
                            }];
}

- (void)languageItemSelectedNotification:(NSNotification *)notification
{
    // Ensure action is only taken if the secondary menu view controller presented the lang picker.
    LanguagesTableVC *languagesTableVC = notification.object;
    if (languagesTableVC.invokingVC != self) return;

    NSDictionary *selectedLangInfo = [notification userInfo];
    
    [self showAlert:MWLocalizedString(@"main-menu-language-selection-saved", nil)];
    [self fadeAlert];
    
    [self switchPreferredLanguageToId:selectedLangInfo[@"code"] name:selectedLangInfo[@"name"]];
    
    [self hidePresenter];
}

-(void)switchPreferredLanguageToId:(NSString *)languageId name:(NSString *)name
{
    [SessionSingleton sharedInstance].domain = languageId;
    [SessionSingleton sharedInstance].domainName = name;
    
    NSString *mainArticleTitle = [SessionSingleton sharedInstance].domainMainArticleTitle;
    if (mainArticleTitle) {
        // Invalidate cache so present day main page article is always retrieved.
        [NAV loadArticleWithTitle: mainArticleTitle
                           domain: languageId
                         animated: YES
                  discoveryMethod: DISCOVERY_METHOD_SEARCH
                invalidatingCache: YES];
    }
}

#pragma mark - Animation

-(void)animateArticleTitleMovingToSavedPages
{
    UILabel *savedPagesLabel = [self getViewWithTag:SECONDARY_MENU_ROW_INDEX_SAVED_PAGES].textLabel;
    UILabel *articleTitleLabel = [self getViewWithTag:SECONDARY_MENU_ROW_INDEX_SAVE_PAGE].textLabel;
    
    CGAffineTransform scale = CGAffineTransformMakeScale(0.4, 0.4);
    CGPoint destPoint = [self getLocationForView:savedPagesLabel xf:scale];
    
    NSString *title = MWLocalizedString(@"main-menu-current-article-save", nil);
    NSAttributedString *attributedTitle =
    [title attributedStringWithAttributes: @{NSForegroundColorAttributeName: [UIColor clearColor]}
                      substitutionStrings: @[[SessionSingleton sharedInstance].currentArticleTitle]
                   substitutionAttributes: @[
                                             @{
                                                 NSFontAttributeName: [UIFont italicSystemFontOfSize:16],
                                                 NSForegroundColorAttributeName: [UIColor blackColor]
                                                 }]
     ];
    
    for (NSInteger i = 0; i < 4; i++) {

        UILabel *label = [self getLabelCopyToAnimate:articleTitleLabel];
        label.attributedText = attributedTitle;

        [self animateView: label
            toDestination: destPoint
               afterDelay: (i * 0.06)
                 duration: 0.45f
                transform: scale];
    }

    [savedPagesLabel animateAndRewindXF: CATransform3DMakeScale(1.08f, 1.08f, 1.0f)
                             afterDelay: 0.32
                               duration: 0.16
                                   then: nil];
}

-(UILabel *)getLabelCopyToAnimate:(UILabel *)labelToCopy
{
    UILabel *labelCopy = [[UILabel alloc] init];
    CGRect sourceRect = [labelToCopy convertRect:labelToCopy.bounds toView:self.view];
    labelCopy.frame = sourceRect;
    labelCopy.text = labelToCopy.text;
    labelCopy.font = labelToCopy.font;
    labelCopy.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    labelCopy.backgroundColor = [UIColor clearColor];
    labelCopy.textAlignment = labelToCopy.textAlignment;
    labelCopy.lineBreakMode = labelToCopy.lineBreakMode;
    labelCopy.numberOfLines = labelToCopy.numberOfLines;
    [self.view addSubview:labelCopy];
    return labelCopy;
}

-(CGPoint)getLocationForView:(UIView *)view xf:(CGAffineTransform)xf
{
    CGPoint point = [view convertPoint:view.center toView:self.view];
    CGPoint scaledPoint = [view convertPoint:CGPointApplyAffineTransform(view.center, xf) toView:self.view];
    scaledPoint.y = point.y;
    return scaledPoint;
}

-(void)animateView: (UIView *)view
     toDestination: (CGPoint)destPoint
        afterDelay: (CGFloat)delay
          duration: (CGFloat)duration
         transform: (CGAffineTransform)xf
{
    [UIView animateWithDuration: duration
                          delay: delay
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^{
                         view.center = destPoint;
                         view.alpha = 0.3f;
                         view.transform = xf;
                     }completion: ^(BOOL finished) {
                         [view removeFromSuperview];
                     }];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Scroll

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideKeyboard];
}

/*
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.scrollView.orientation = !self.scrollView.orientation;
}
*/

@end
