//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BottomMenuViewController.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "SessionSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "WikiGlyph_Chars_iOS.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "UIViewController+Alert.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "NSString+Extras.h"
#import "ShareMenuSavePageActivity.h"
#import "Article+Convenience.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "WMF_Colors.h"
#import "UIViewController+ModalPresent.h"
#import "UIViewController+ModalsSearch.h"
#import "UIViewController+ModalPop.h"
#import "NSObject+ConstraintsScale.h"

typedef NS_ENUM(NSInteger, BottomMenuItemTag) {
    BOTTOM_MENU_BUTTON_UNKNOWN,
    BOTTOM_MENU_BUTTON_PREVIOUS,
    BOTTOM_MENU_BUTTON_NEXT,
    BOTTOM_MENU_BUTTON_SHARE,
    BOTTOM_MENU_BUTTON_SAVE
};

@interface BottomMenuViewController ()

@property (weak, nonatomic) IBOutlet WikiGlyphButton *backButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton *forwardButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton *saveButton;
@property (weak, nonatomic) IBOutlet WikiGlyphButton *rightButton;

@property (strong, nonatomic) NSDictionary *adjacentHistoryEntries;

@property (strong, nonatomic) NSArray *allButtons;

@property (strong, nonatomic) UIPopoverController *popover;

@end

@implementation BottomMenuViewController{

    ArticleDataContextSingleton *articleDataContext_;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    UIColor *buttonColor = [UIColor blackColor];

    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

    [self.backButton.label setWikiText: isRTL ? IOS_WIKIGLYPH_FORWARD : IOS_WIKIGLYPH_BACKWARD
                                 color: buttonColor
                                  size: MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset: 0];
    self.backButton.accessibilityLabel = MWLocalizedString(@"menu-back-accessibility-label", nil);
    self.backButton.tag = BOTTOM_MENU_BUTTON_PREVIOUS;
    
    [self.forwardButton.label setWikiText: isRTL ? IOS_WIKIGLYPH_BACKWARD : IOS_WIKIGLYPH_FORWARD
                                    color: buttonColor
                                     size: MENU_BOTTOM_GLYPH_FONT_SIZE
                           baselineOffset: 0
     ];
    self.forwardButton.accessibilityLabel = MWLocalizedString(@"menu-forward-accessibility-label", nil);
    self.forwardButton.tag = BOTTOM_MENU_BUTTON_NEXT;
    // self.forwardButton.label.transform = CGAffineTransformMakeScale(-1, 1);

    [self.rightButton.label setWikiText: IOS_WIKIGLYPH_SHARE
                                  color: buttonColor
                                   size: MENU_BOTTOM_GLYPH_FONT_SIZE
                         baselineOffset: 0
     ];
    self.rightButton.tag = BOTTOM_MENU_BUTTON_SHARE;
    self.rightButton.accessibilityLabel = MWLocalizedString(@"menu-share-accessibility-label", nil);

    [self.saveButton.label setWikiText: IOS_WIKIGLYPH_HEART_OUTLINE
                                 color: buttonColor
                                  size: MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset: 0
     ];
    self.saveButton.tag = BOTTOM_MENU_BUTTON_SAVE;
    self.saveButton.accessibilityLabel = MWLocalizedString(@"share-menu-save-page", nil);

    self.allButtons = @[self.backButton, self.forwardButton, self.rightButton, self.saveButton];

    self.view.backgroundColor = CHROME_COLOR;

    [self addTapRecognizersToAllButtons];
    
    UILongPressGestureRecognizer *saveLongPressRecognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                  action: @selector(saveButtonLongPressed:)];
    saveLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.saveButton addGestureRecognizer:saveLongPressRecognizer];

    UILongPressGestureRecognizer *backLongPressRecognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                  action: @selector(backForwardButtonsLongPressed:)];
    backLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.backButton addGestureRecognizer:backLongPressRecognizer];


    UILongPressGestureRecognizer *forwardLongPressRecognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                  action: @selector(backForwardButtonsLongPressed:)];
    forwardLongPressRecognizer.minimumPressDuration = 0.5f;
    [self.forwardButton addGestureRecognizer:forwardLongPressRecognizer];

    [self adjustConstraintsScaleForViews:@[self.backButton, self.forwardButton, self.saveButton, self.rightButton]];
}

-(void)addTapRecognizersToAllButtons
{
    for (WikiGlyphButton *view in self.allButtons) {
        [view addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget: self
                                                 action: @selector(buttonPushed:)]];
    }
}

#pragma mark Bottom bar button methods

- (void)buttonPushed:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // If the tapped item was a button, first animate it briefly, then perform action.
        if([recognizer.view isKindOfClass:[WikiGlyphButton class]]){
            WikiGlyphButton *button = (WikiGlyphButton *)recognizer.view;
            if (!button.enabled)return;
            CGFloat animationScale = 1.25f;
            [button.label animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                                  afterDelay: 0.0
                                    duration: 0.06f
                                        then: ^{
                                            [self performActionForButton:button];
                                        }];
        }
    }
}

- (void)performActionForButton:(WikiGlyphButton *)button
{
    switch (button.tag) {
        case BOTTOM_MENU_BUTTON_PREVIOUS:
            [self backButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_NEXT:
            [self forwardButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_SHARE:
            [self shareButtonPushed];
            break;
        case BOTTOM_MENU_BUTTON_SAVE:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
            [self updateBottomBarButtonsEnabledState];
            break;
        default:
            break;
    }
}

-(void)saveButtonLongPressed:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan){
        [self performModalSequeWithID: @"modal_segue_show_saved_pages"
                      transitionStyle: UIModalTransitionStyleCoverVertical
                                block: nil];
    }
}

-(void)backForwardButtonsLongPressed:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan){
        [self performModalSequeWithID: @"modal_segue_show_history"
                      transitionStyle: UIModalTransitionStyleCoverVertical
                                block: nil];
    }
}

- (void)shareButtonPushed
{
    NSString *title = @"";
    NSURL *desktopURL = nil;
    UIImage *image = nil;

    MWKArticle *article = [SessionSingleton sharedInstance].article;
    if (article) {
        desktopURL = article.title.desktopURL;
        title = article.title.prefixedText;
        
        MWKImage *thumbnail = article.thumbnail;
        if (thumbnail) {
            image = [thumbnail asUIImage];
        }
    }
    
    if (!desktopURL) {
        NSLog(@"Could not retrieve desktop URL for article.");
        return;
    }
    
    //ShareMenuSavePageActivity *shareMenuSavePageActivity = [[ShareMenuSavePageActivity alloc] init];

    NSMutableArray *activityItemsArray = @[title, desktopURL].mutableCopy;
    if (image) {
        [activityItemsArray addObject:image];
    }

    UIActivityViewController *shareActivityVC =
        [[UIActivityViewController alloc] initWithActivityItems: activityItemsArray
                                          applicationActivities: @[/*shareMenuSavePageActivity*/]];
    NSMutableArray *exclusions = @[
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeSaveToCameraRoll
    ].mutableCopy;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [exclusions addObject:UIActivityTypeAirDrop];
        [exclusions addObject:UIActivityTypeAddToReadingList];
    }

    shareActivityVC.excludedActivityTypes = exclusions;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:shareActivityVC animated:YES completion:nil];
    } else {
        // iPad crashes if you present share dialog modally. Whee!
        self.popover = [[UIPopoverController alloc] initWithContentViewController:shareActivityVC];
        [self.popover presentPopoverFromRect:self.saveButton.frame
                                 inView:self.view
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    }
    
    [shareActivityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
        NSLog(@"activityType = %@", activityType);
    }];
}

- (void)backButtonPushed
{
    MWKHistoryEntry *historyEntry = self.adjacentHistoryEntries[@"before"];
    if (historyEntry){
        WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC showAlert:historyEntry.title.prefixedText type:ALERT_TYPE_BOTTOM duration:0.8];

        [webVC navigateToPage: historyEntry.title
              discoveryMethod: MWK_DISCOVERY_METHOD_BACKFORWARD
            invalidatingCache: NO
         showLoadingIndicator: YES];
    }
}

- (void)forwardButtonPushed
{
    MWKHistoryEntry *historyEntry = self.adjacentHistoryEntries[@"after"];
    if (historyEntry){
        WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

        [webVC showAlert:historyEntry.title.prefixedText type:ALERT_TYPE_BOTTOM duration:0.8];

        [webVC navigateToPage: historyEntry.title
             discoveryMethod: MWK_DISCOVERY_METHOD_BACKFORWARD
            invalidatingCache: NO
         showLoadingIndicator: YES];
    }
}

-(NSDictionary *)getAdjacentHistoryEntries
{
    SessionSingleton *session = [SessionSingleton sharedInstance];
    MWKHistoryList *historyList = session.userDataStore.historyList;

    MWKHistoryEntry *currentHistoryEntry = [historyList entryForTitle:session.title];
    MWKHistoryEntry *beforeHistoryEntry = [historyList entryBeforeEntry:currentHistoryEntry];
    MWKHistoryEntry *afterHistoryEntry = [historyList entryAfterEntry:currentHistoryEntry];

    NSMutableDictionary *result = [@{} mutableCopy];
    if(beforeHistoryEntry) result[@"before"] = beforeHistoryEntry;
    if(currentHistoryEntry) result[@"current"] = currentHistoryEntry;
    if(afterHistoryEntry) result[@"after"] = afterHistoryEntry;

    return result;
}

-(void)updateBottomBarButtonsEnabledState
{
    self.adjacentHistoryEntries = [self getAdjacentHistoryEntries];
    self.forwardButton.enabled = (self.adjacentHistoryEntries[@"after"]) ? YES : NO;
    self.backButton.enabled = (self.adjacentHistoryEntries[@"before"]) ? YES : NO;

    NSString *saveIconString = IOS_WIKIGLYPH_HEART_OUTLINE;
    UIColor *saveIconColor = [UIColor blackColor];
    if([self isCurrentArticleSaved]){
        saveIconString = IOS_WIKIGLYPH_HEART;
        saveIconColor = UIColorFromRGBWithAlpha(0xf27072, 1.0);
    }
    
    [self.saveButton.label setWikiText: saveIconString
                                 color: saveIconColor
                                  size: MENU_BOTTOM_GLYPH_FONT_SIZE
                        baselineOffset: 0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)isCurrentArticleSaved
{
    SessionSingleton *session = [SessionSingleton sharedInstance];
    return [session.userDataStore.savedPageList isSaved:session.title];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
