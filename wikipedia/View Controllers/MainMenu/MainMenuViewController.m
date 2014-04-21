//  Created by Monte Hurd on 12/18/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MainMenuViewController.h"
#import "SessionSingleton.h"
#import "LoginViewController.h"
#import "HistoryViewController.h"
#import "SavedPagesViewController.h"
#import "QueuesSingleton.h"
#import "DownloadTitlesForRandomArticlesOp.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "WikipediaAppUtils.h"
#import "NavController.h"
#import "LanguagesTableVC.h"

#import "UINavigationController+SearchNavStack.h"
#import "UIViewController+HideKeyboard.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "UIViewController+Alert.h"
#import "UIImage+ColorMask.h"
#import "NSString+FormattedAttributedString.h"
#import "TabularScrollView.h"

#import "MainMenuRowView.h"
#import "PageHistoryViewController.h"
#import "CreditsViewController.h"

#pragma mark - Defines

#define NAV ((NavController *)self.navigationController)
#define BACKGROUND_COLOR [UIColor colorWithWhite:0.97f alpha:1.0f]

typedef enum {
    ROW_INDEX_LOGIN = 0,
    ROW_INDEX_RANDOM = 1,
    ROW_INDEX_HISTORY = 2,
    ROW_INDEX_SAVED_PAGES = 3,
    ROW_INDEX_SAVE_PAGE = 4,
    ROW_INDEX_SEARCH_LANGUAGE = 5,
    ROW_INDEX_ZERO_WARN_WHEN_LEAVING = 6,
    ROW_INDEX_SEND_FEEDBACK = 7,
    ROW_INDEX_PAGE_HISTORY = 8,
    ROW_INDEX_CREDITS = 9
} MainMenuRowIndex;

#pragma mark - Private

@interface MainMenuViewController(){

}

@property (strong, nonatomic) IBOutlet TabularScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *rowData;
@property (strong, nonatomic) NSMutableArray *rowViews;
@property (nonatomic) BOOL hidePagesSection;

@property (strong, nonatomic) NSDictionary *highlightedTextAttributes;

@end

@implementation MainMenuViewController

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

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(tabularScrollViewItemTappedNotification:)
                                                 name: @"TabularScrollViewItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"TabularScrollViewItemTapped"
                                                  object: nil];
    [[QueuesSingleton sharedInstance].randomArticleQ cancelAllOperations];

    [super viewWillDisappear:animated];
}

#pragma mark - Access

-(MainMenuRowIndex)getIndexOfRow:(NSDictionary *)row
{
    return ((NSNumber *)row[@"tag"]).integerValue;
}

-(MainMenuRowView *)getViewWithTag:(MainMenuRowIndex)tag
{
    for (MainMenuRowView *view in self.rowViews) {
        if(view.tag== tag) return view;
    }
    return nil;
}

-(NSMutableDictionary *)getRowWithTag:(MainMenuRowIndex)tag
{
    for (NSMutableDictionary *row in self.rowData) {
        MainMenuRowIndex index = [self getIndexOfRow:row];
        if (tag == index) return row;
    }
    return nil;
}

#pragma mark - Rows

-(void)deleteRowWithTag:(MainMenuRowIndex)tag
{
    NSMutableDictionary *rowToDelete = [self getRowWithTag:tag];
    if (rowToDelete) [self.rowData removeObject:rowToDelete];
}

-(void)loadRowViews
{
    // Don't forget - had to select "File's Owner" in left column of xib and then choose
    // this view controller in the Identity Inspector (3rd icon from left in right column)
    // in the Custom Class / Class dropdown. See: http://stackoverflow.com/a/21991592
    UINib *mainMenuRowViewNib = [UINib nibWithNibName:@"MainMenuRowView" bundle:nil];

    [self setRowData];

    for (NSUInteger i = 0; i < self.rowData.count; i++) {
        NSMutableDictionary *row = self.rowData[i];

        MainMenuRowView *rowView = [[mainMenuRowViewNib instantiateWithOwner:self options:nil] firstObject];

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
        MainMenuRowIndex index = [self getIndexOfRow:row];
        MainMenuRowView *rowView = [self getViewWithTag:index];

        rowView.highlighted = ((NSNumber *)row[@"highlighted"]).boolValue;

        rowView.imageName = row[@"imageName"];

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
                                                                 substitutionAttributes: @[self.self.highlightedTextAttributes]
     ];
    
    NSAttributedString *saveArticleTitle =
    [MWLocalizedString(@"main-menu-current-article-save", nil) attributedStringWithAttributes: nil
                                                                          substitutionStrings: @[currentArticleTitle]
                                                                       substitutionAttributes: @[self.self.highlightedTextAttributes]
     ];

    NSAttributedString *pageHistoryTitle =
    [MWLocalizedString(@"main-menu-show-page-history", nil) attributedStringWithAttributes: nil
                                                                       substitutionStrings: @[currentArticleTitle]
                                                                    substitutionAttributes: @[self.self.highlightedTextAttributes]
     ];
    
    NSMutableArray *rowData =
    @[
      @{
          @"title": @"",
          @"tag": @(ROW_INDEX_LOGIN),
          @"imageName": @"",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"main-menu-random", nil),
          @"tag": @(ROW_INDEX_RANDOM),
          @"imageName": @"main_menu_dice_white.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"main-menu-show-history", nil),
          @"tag": @(ROW_INDEX_HISTORY),
          @"imageName": @"main_menu_clock_white.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"main-menu-show-saved", nil),
          @"tag": @(ROW_INDEX_SAVED_PAGES),
          @"imageName": @"main_menu_bookmark_white.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": saveArticleTitle,
          @"tag": @(ROW_INDEX_SAVE_PAGE),
          @"imageName": @"main_menu_save.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"domain": [SessionSingleton sharedInstance].domain,
          @"title": searchWikiTitle,
          @"tag": @(ROW_INDEX_SEARCH_LANGUAGE),
          @"imageName": @"main_menu_foreign_characters_gray.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"zero-warn-when-leaving", nil),
          @"tag": @(ROW_INDEX_ZERO_WARN_WHEN_LEAVING),
          @"imageName": @"main_menu_flag_white.png",
          @"highlighted": @([SessionSingleton sharedInstance].zeroConfigState.warnWhenLeaving),
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"main-menu-send-feedback", nil),
          @"tag": @(ROW_INDEX_SEND_FEEDBACK),
          @"imageName": @"main_menu_envelope_white.png",
          @"highlighted": @YES,
          }.mutableCopy
      ,
      @{
          @"title": pageHistoryTitle,
          @"tag": @(ROW_INDEX_PAGE_HISTORY),
          @"imageName": @"main_menu_save.png",
          @"highlighted": @YES,
          }.mutableCopy
        ,
      @{
          @"domain": [SessionSingleton sharedInstance].domain,
          @"title": MWLocalizedString(@"main-menu-credits", nil),
          @"tag": @(ROW_INDEX_CREDITS),
          @"imageName": @"main_menu_foreign_characters_gray.png",
          @"highlighted": @YES,
          }.mutableCopy
      ].mutableCopy;

    self.rowData = rowData;
    
    if(self.hidePagesSection){
        [self deleteRowWithTag:ROW_INDEX_SAVE_PAGE];
        [self deleteRowWithTag:ROW_INDEX_PAGE_HISTORY];
    }
}

-(void)updateLoginRow
{
    id loginTitle = nil;
    NSString *loginImageName = nil;
    NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if(userName){
        loginTitle = [MWLocalizedString(@"main-menu-account-logout", nil) stringByAppendingString:@" $1"];

        loginTitle =
        [loginTitle attributedStringWithAttributes: nil
                                substitutionStrings: @[userName]
                             substitutionAttributes: @[self.highlightedTextAttributes]
         ];
        
        loginImageName = @"main_menu_face_smile_white.png";
    }else{
        loginTitle = MWLocalizedString(@"main-menu-account-login", nil);
        loginImageName = @"main_menu_face_sleep_white.png";
    }
    
    NSMutableDictionary *row = [self getRowWithTag:ROW_INDEX_LOGIN];
    row[@"title"] = loginTitle;
    row[@"imageName"] = loginImageName;
}

#pragma mark - Selection

- (void)tabularScrollViewItemTappedNotification:(NSNotification *)notification
{
    CGFloat animationDuration = 0.08f;
    NSDictionary *userInfo = [notification userInfo];
    MainMenuRowView *tappedItem = userInfo[@"tappedItem"];
    
    if (tappedItem.tag == ROW_INDEX_ZERO_WARN_WHEN_LEAVING) animationDuration = 0.0f;
    
    void(^performTapAction)() = ^(){
    
        switch (tappedItem.tag) {
            case ROW_INDEX_LOGIN:
            {
                NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
                if (!userName) {
                    LoginViewController *loginVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                    [NAV pushViewController:loginVC animated:YES];
                }else{
                    
                    [SessionSingleton sharedInstance].keychainCredentials.userName = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.password = nil;
                    [SessionSingleton sharedInstance].keychainCredentials.editTokens = nil;
                    
                    // Clear session cookies too.
                    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
                    }
                }
            }
                break;
            case ROW_INDEX_RANDOM:
                [self showAlert:MWLocalizedString(@"fetching-random-article", nil)];
                [self fetchRandomArticle];
                break;
            case ROW_INDEX_HISTORY:
            {
                HistoryViewController *historyVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"HistoryViewController"];
                [NAV pushViewController:historyVC animated:YES];
            }
                break;
            case ROW_INDEX_SAVED_PAGES:
            {
                SavedPagesViewController *savedPagesVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"SavedPagesViewController"];
                [NAV pushViewController:savedPagesVC animated:YES];
            }
                break;
            case ROW_INDEX_SAVE_PAGE:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
                [self animateArticleTitleMovingToSavedPages];
                break;
            case ROW_INDEX_SEARCH_LANGUAGE:
                [self showLanguages];
                break;
            case ROW_INDEX_ZERO_WARN_WHEN_LEAVING:
                [[SessionSingleton sharedInstance].zeroConfigState toggleWarnWhenLeaving];
                break;
            case ROW_INDEX_SEND_FEEDBACK:
            {
                NSString *mailtoUri =
                [NSString stringWithFormat:@"mailto:mobile-ios-wikipedia@wikimedia.org?subject=Feedback:%@", [WikipediaAppUtils versionedUserAgent]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailtoUri]];
            }
                break;
            case ROW_INDEX_PAGE_HISTORY:
            {
                PageHistoryViewController *pageHistoryVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"PageHistoryViewController"];
                [NAV pushViewController:pageHistoryVC animated:YES];
            }
                break;
            case ROW_INDEX_CREDITS:
            {
                CreditsViewController *creditsVC =
                    [NAV.storyboard instantiateViewControllerWithIdentifier:@"CreditsViewController"];
                [NAV pushViewController:creditsVC animated:YES];
            }
                break;
            default:
                break;
        }
        
        [self loadRowViews];
    };

    CGFloat animationScale = 1.28f;
    
    NSMutableDictionary *row = [self getRowWithTag:tappedItem.tag];
    
    NSString *imageName = [row objectForKey:@"imageName"];

    if (imageName && (imageName.length > 0) && (animationDuration > 0)) {
        [tappedItem.thumbnailImageView animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
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
    LanguagesTableVC *languagesTableVC =
    [NAV.storyboard instantiateViewControllerWithIdentifier:@"LanguagesTableVC"];
    
    languagesTableVC.downloadLanguagesForCurrentArticle = NO;
    
    CATransition *transition = [languagesTableVC getTransition];
    
    languagesTableVC.selectionBlock = ^(NSDictionary *selectedLangInfo){

        [self showAlert:MWLocalizedString(@"main-menu-language-selection-saved", nil)];
        [self showAlert:@""];

        [self switchPreferredLanguageToId:selectedLangInfo[@"code"] name:selectedLangInfo[@"name"]];
        
        [NAV.view.layer addAnimation:transition forKey:nil];
        // Don't animate - so the transistion set above will be used.
        [NAV popViewControllerAnimated:NO];

    };
    
    [NAV.view.layer addAnimation:transition forKey:nil];
    // Don't animate - so the transistion set above will be used.
    [NAV pushViewController:languagesTableVC animated:NO];
}

-(void)switchPreferredLanguageToId:(NSString *)languageId name:(NSString *)name
{
    [SessionSingleton sharedInstance].domain = languageId;
    [SessionSingleton sharedInstance].domainName = name;
}

-(void)fetchRandomArticle {

    [[QueuesSingleton sharedInstance].randomArticleQ cancelAllOperations];

    DownloadTitlesForRandomArticlesOp *downloadTitlesForRandomArticlesOp =
        [[DownloadTitlesForRandomArticlesOp alloc] initForDomain: [SessionSingleton sharedInstance].domain
                                                 completionBlock: ^(NSString *title) {
                                                     if (title) {
                                                         dispatch_async(dispatch_get_main_queue(), ^(){
                                                             [NAV loadArticleWithTitle: title
                                                                                domain: [SessionSingleton sharedInstance].domain
                                                                              animated: YES
                                                                       discoveryMethod: DISCOVERY_METHOD_RANDOM];
                                                         });
                                                     }
                                                 } cancelledBlock: ^(NSError *errorCancel) {
                                                    [self showAlert:@""];
                                                 } errorBlock: ^(NSError *error) {
                                                    [self showAlert:error.localizedDescription];
                                                 }];

    [[QueuesSingleton sharedInstance].randomArticleQ addOperation:downloadTitlesForRandomArticlesOp];
}

#pragma mark - Animation

-(void)animateArticleTitleMovingToSavedPages
{
    UILabel *savedPagesLabel = [self getViewWithTag:ROW_INDEX_SAVED_PAGES].textLabel;
    UILabel *articleTitleLabel = [self getViewWithTag:ROW_INDEX_SAVE_PAGE].textLabel;
    
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
