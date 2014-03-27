//  Created by Monte Hurd on 1/13/14.

#import "SectionEditorViewController.h"

#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"
#import "UIViewController+Alert.h"
#import "QueuesSingleton.h"
#import "DownloadSectionWikiTextOp.h"
#import "NavController.h"
#import "PreviewAndSaveViewController.h"
#import "UIButton+ColorMask.h"
#import "WMF_Colors.h"

#define EDIT_TEXT_VIEW_FONT [UIFont systemFontOfSize:14.0f]
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN 25.0f
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX 25.0f

#define NAV ((NavController *)self.navigationController)

@interface SectionEditorViewController (){
    ArticleDataContextSingleton *articleDataContext_;
}

@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (strong, nonatomic) NSString *unmodifiedWikiText;

@end

@implementation SectionEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationItem.hidesBackButton = YES;
    self.unmodifiedWikiText = nil;

    [self.editTextView setDelegate:self];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self loadLatestWikiTextForSectionFromServer];

    if ([self.editTextView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.editTextView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self highlightProgressiveButton:[self changesMade]];
}

-(BOOL)changesMade
{
    if (!self.unmodifiedWikiText) return NO;
    return ![self.unmodifiedWikiText isEqualToString:self.editTextView.text];
}

-(void)highlightProgressiveButton:(BOOL)highlight
{
    static BOOL lastHightlight = NO;
    if (lastHightlight == highlight) return;
    lastHightlight = highlight;

    UIButton *button = (UIButton *)[NAV getNavBarItem:NAVBAR_BUTTON_EYE];

    button.backgroundColor = highlight ?
        WMF_COLOR_BLUE
        :
        [UIColor clearColor];
    
    [button maskButtonImageWithColor: highlight ?
        [UIColor whiteColor]
        :
        [UIColor blackColor]
     ];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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
    NAV.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self setScrollsToTop:NO];

    [self highlightProgressiveButton:NO];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NavItemTapped" object:nil];

    NAV.navBarMode = NAVBAR_MODE_SEARCH;

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    [super viewWillDisappear:animated];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_EYE:
            if (![self changesMade]) {
                [self showAlert:NSLocalizedString(@"wikitext-preview-changes-none", nil)];
                [self showAlert:@""];
                break;
            }
            [self preview];
            break;
        case NAVBAR_BUTTON_X:
            [self cancelPushed:nil];
            break;
        case NAVBAR_LABEL:
        case NAVBAR_BUTTON_PENCIL:
            [self showHTMLAlert: @""
                    bannerImage: nil
                    bannerColor: nil
             ];
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

-(void)loadLatestWikiTextForSectionFromServer
{
    [self showAlert:NSLocalizedString(@"wikitext-downloading", nil)];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];
    
    DownloadSectionWikiTextOp *downloadWikiTextOp = [[DownloadSectionWikiTextOp alloc] initForPageTitle:section.article.title domain:section.article.domain section:section.index completionBlock:^(NSString *revision){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            [self showAlert:NSLocalizedString(@"wikitext-download-success", nil)];
            [self showAlert:@""];
            self.unmodifiedWikiText = revision;
            self.editTextView.attributedText = [self getAttributedString:revision];
            //[self.editTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4f];
            //[self performSelector:@selector(setCursor:) withObject:self.editTextView afterDelay:0.45];
            [self adjustScrollInset];
        }];
        
    } cancelledBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        
    }];

    [[QueuesSingleton sharedInstance].sectionWikiTextDownloadQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].sectionWikiTextDownloadQ addOperation:downloadWikiTextOp];
}

-(void)adjustScrollInset
{
    // Ensure the edit text view can scroll whatever text it is displaying all the
    // way so the bottom of the text can be scrolled to the top of the screen.
    CGFloat bottomInset = self.view.bounds.size.height - 60;
    self.editTextView.contentInset = UIEdgeInsetsMake(0, 0, bottomInset, 0);
}

- (void)setCursor:(UITextView *)textView
{ 
    textView.selectedRange = NSMakeRange(0, 0);
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustScrollInset];
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
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
    previewVC.sectionID = self.sectionID;
    previewVC.wikiText = self.editTextView.text;
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (void)cancelPushed:(id)sender
{
    [self hide];
}

-(void)hide
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
