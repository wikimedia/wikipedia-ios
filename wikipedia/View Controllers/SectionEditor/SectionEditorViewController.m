//  Created by Monte Hurd on 1/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SectionEditorViewController.h"

#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"
#import "UIViewController+Alert.h"
#import "QueuesSingleton.h"
#import "WikiTextSectionFetcher.h"
#import "CenterNavController.h"
#import "PreviewAndSaveViewController.h"
#import "WMF_Colors.h"
#import "MWLanguageInfo.h"

#import "MenuButton.h"

#import "RootViewController.h"
#import "TopMenuViewController.h"

#define EDIT_TEXT_VIEW_FONT [UIFont systemFontOfSize:16.0f * MENUS_SCALE_MULTIPLIER]
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN (25.0f * MENUS_SCALE_MULTIPLIER)
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX (25.0f * MENUS_SCALE_MULTIPLIER)

@interface SectionEditorViewController (){
    ArticleDataContextSingleton *articleDataContext_;
}

@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (strong, nonatomic) NSString *unmodifiedWikiText;
@property (nonatomic) CGRect viewKeyboardRect;

@end

@implementation SectionEditorViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

/*
- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationItem.hidesBackButton = YES;
    self.unmodifiedWikiText = nil;

    [self.editTextView setDelegate:self];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        // Fix for strange ios 7 bug with large pages of text in the edit text view
        // jumping around if scrolled quickly.
        self.editTextView.layoutManager.allowsNonContiguousLayout = NO;
    }
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self loadLatestWikiTextForSectionFromServer];

    if ([self.editTextView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.editTextView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }
    
    self.viewKeyboardRect = CGRectNull;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self highlightProgressiveButton:[self changesMade]];
    
    [self scrollTextViewSoCursorNotUnderKeyboard:textView];
}

-(BOOL)changesMade
{
    if (!self.unmodifiedWikiText) return NO;
    return ![self.unmodifiedWikiText isEqualToString:self.editTextView.text];
}

-(void)highlightProgressiveButton:(BOOL)highlight
{
    [[ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_NEXT] setEnabled:highlight];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self registerForKeyboardNotifications];

    [self setScrollsToTop:YES];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navItemTappedNotification:) name:@"NavItemTapped" object:nil];
    
    [self highlightProgressiveButton:[self changesMade]];
    
    if([self changesMade]){
        // Needed to keep keyboard on screen when cancelling out of preview.
        [self.editTextView becomeFirstResponder];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Change the nav bar layout.
    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self setScrollsToTop:NO];

    [self unRegisterForKeyboardNotifications];

    [self highlightProgressiveButton:NO];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NavItemTapped" object:nil];

    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_DEFAULT;

    [super viewWillDisappear:animated];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_NEXT:
            if (![self changesMade]) {
                [self showAlert:MWLocalizedString(@"wikitext-preview-changes-none", nil) type:ALERT_TYPE_TOP duration:1];
                break;
            }
            [self preview];
            break;
        case NAVBAR_BUTTON_ARROW_LEFT:
            [self cancelPushed:nil];
            break;
        default:
            break;
    }
}

-(void)setScrollsToTop:(BOOL)scrollsToTop
{
    // A view controller's UIScrollView will only scroll to top (if title bar tapped) if
    // its UIScrollView the *only* one with "scrollsToTop" set to YES.
    self.editTextView.scrollsToTop = scrollsToTop;
    for (UIView *v in [self.parentViewController.view.subviews copy]) {
        if ([v respondsToSelector:@selector(scrollView)]) {
            UIScrollView *s = [v performSelector:@selector(scrollView) withObject:nil];
            s.scrollsToTop = !scrollsToTop;
        }
    }
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[WikiTextSectionFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                WikiTextSectionFetcher *wikiTextSectionFetcher = (WikiTextSectionFetcher *)sender;
                NSDictionary *resultsDict = (NSDictionary *)fetchedData;
                NSString *revision = resultsDict[@"revision"];
                NSDictionary *userInfo = resultsDict[@"userInfo"];
                
                self.funnel = [[EditFunnel alloc] initWithUserId:[userInfo[@"id"] intValue]];
                [self.funnel logStart];

                MWKProtectionStatus *protectionStatus = wikiTextSectionFetcher.section.article.protection;

                if (protectionStatus && [[protectionStatus allowedGroupsForAction:@"edit"] count] > 0) {
                    NSArray *groups = [protectionStatus allowedGroupsForAction:@"edit"];
                    NSString *msg;
                    if ([groups indexOfObject:@"autoconfirmed"] != NSNotFound) {
                        msg = MWLocalizedString(@"page_protected_autoconfirmed", nil);
                    } else if ([groups indexOfObject:@"sysop"] != NSNotFound) {
                        msg = MWLocalizedString(@"page_protected_sysop", nil);
                    } else {
                        msg = MWLocalizedString(@"page_protected_other", nil);
                    }
                    [self showAlert:msg type:ALERT_TYPE_TOP duration:1];
                } else {
                    //[self showAlert:MWLocalizedString(@"wikitext-download-success", nil) type:ALERT_TYPE_TOP duration:1];
                    [self fadeAlert];
                }
                self.unmodifiedWikiText = revision;
                self.editTextView.attributedText = [self getAttributedString:revision];
                //[self.editTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4f];
                
                MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:wikiTextSectionFetcher.section.article.site.domain];
                UITextRange *range = [self.editTextView textRangeFromPosition:self.editTextView.beginningOfDocument toPosition: self.editTextView.endOfDocument];
                if ([lang.dir isEqualToString:@"rtl"]) {
                    [self.editTextView setBaseWritingDirection:UITextWritingDirectionRightToLeft forRange:range];
                } else {
                    [self.editTextView setBaseWritingDirection:UITextWritingDirectionLeftToRight forRange:range];
                }
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:{
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
            }
                break;
            case FETCH_FINAL_STATUS_FAILED:{
                NSString *errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];
            }
                break;
        }
    }
}

-(void)loadLatestWikiTextForSectionFromServer
{
    [self showAlert:MWLocalizedString(@"wikitext-downloading", nil) type:ALERT_TYPE_TOP duration:-1];

    [[QueuesSingleton sharedInstance].sectionWikiTextDownloadManager.operationQueue cancelAllOperations];

    (void)[[WikiTextSectionFetcher alloc] initAndFetchWikiTextForSection: self.section
                                                             withManager: [QueuesSingleton sharedInstance].sectionWikiTextDownloadManager
                                                      thenNotifyDelegate: self];
}

-(NSAttributedString *)getAttributedString:(NSString *)string
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.maximumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MIN;
    paragraphStyle.minimumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MAX;

    paragraphStyle.headIndent = 10.0;
    paragraphStyle.firstLineHeadIndent = 10.0;
    paragraphStyle.tailIndent = -10.0;

    return
    [[NSAttributedString alloc] initWithString: string
                                    attributes: @{
                                                  NSParagraphStyleAttributeName : paragraphStyle,
                                                  NSFontAttributeName : EDIT_TEXT_VIEW_FONT,
                                                  }];
}

- (void)preview
{
    PreviewAndSaveViewController *previewVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"PreviewViewController"];
    previewVC.section = self.section;
    previewVC.wikiText = self.editTextView.text;
    previewVC.funnel = self.funnel;
    previewVC.savedPagesFunnel = self.savedPagesFunnel;
    [ROOT pushViewController:previewVC animated:YES];
}

- (void)cancelPushed:(id)sender
{
    [self hide];
}

-(void)hide
{
//    [ROOT popViewControllerAnimated:YES];
    [ROOT popViewControllerAnimated:YES];
}

#pragma mark Keyboard

// Ensure the edit text view can scroll whatever text it is displaying all the
// way so the bottom of the text can be scrolled to the top of the screen.
// More info here:
// https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWasShown:)
                                                 name: UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillBeHidden:)
                                                 name: UIKeyboardWillHideNotification object:nil];
}

- (void)unRegisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardDidShowNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardWillHideNotification
                                                  object: nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];

    CGRect windowKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect viewKeyboardRect = [self.view.window convertRect:windowKeyboardRect toView:self.view];

    self.viewKeyboardRect = viewKeyboardRect;

    // This makes it so you can always scroll to the bottom of the text view's text
    // even if the keyboard is onscreen.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, viewKeyboardRect.size.height, 0.0);
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;

    // Mark the text view as needing a layout update so the inset changes above will
    // be taken in to account when the cursor is scrolled onscreen.
    [self.editTextView setNeedsLayout];
    [self.editTextView layoutIfNeeded];
    
    // Scroll cursor onscreen if needed.
    [self scrollTextViewSoCursorNotUnderKeyboard:self.editTextView];
}
 
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;
    
    self.viewKeyboardRect = CGRectNull;
}

- (void)scrollTextViewSoCursorNotUnderKeyboard:(UITextView *)textView
{
    // If cursor is hidden by keyboard, scroll the text view so cursor is onscreen.
    if (!CGRectIsNull(self.viewKeyboardRect)) {
        CGRect cursorRectInTextView = [textView caretRectForPosition:textView.selectedTextRange.start];
        CGRect cursorRectInView = [textView convertRect:cursorRectInTextView toView:self.view];
        if(CGRectIntersectsRect(self.viewKeyboardRect, cursorRectInView)){

            CGFloat margin = -20;
            // Margin here is the amount the cursor will be scrolled above the top of the keyboard.
            cursorRectInTextView = CGRectInset(cursorRectInTextView, 0, margin);

            [textView scrollRectToVisible:cursorRectInTextView animated:YES];
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
