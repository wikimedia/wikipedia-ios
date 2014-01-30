//  Created by Monte Hurd on 1/13/14.

#import "SectionEditorViewController.h"

#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"
#import "UIViewController+Alert.h"
#import "QueuesSingleton.h"
#import "DownloadSectionWikiTextOp.h"
#import "UploadSectionWikiTextOp.h"
#import "SessionSingleton.h"

#define EDIT_TEXT_VIEW_FONT @"AmericanTypewriter"
#define EDIT_TEXT_VIEW_FONT_SIZE 14.0f
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN 25.0f
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX 25.0f

@interface SectionEditorViewController (){
    ArticleDataContextSingleton *articleDataContext_;
    CGFloat scrollViewDragBeganVerticalOffset_;
}

@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *editTextViewTopConstraint;
@property (nonatomic) BOOL showCaptchaContainer;

@end

@implementation SectionEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    self.editTextView.attributedText = [self getAttributedString:@"Loading..."];

    scrollViewDragBeganVerticalOffset_ = 0.0f;
    [self.editTextView setDelegate:self];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    [self.saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];

    [self loadLatestWikiTextForSectionFromServer];
    
    self.captchaId = @"";
    self.editTextViewTopConstraint = nil;

    self.showCaptchaContainer = NO;
    [self updateCaptchaContainerConstraint];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setScrollsToTop:YES];
}

-(void)setScrollsToTop:(BOOL)scrollsToTop
{
    // A view controller's UIScrollView will only scroll to top (if title bar tapped) if
    // its UIScrollView the *only* one with "scrollsToTop" set to YES.
    self.editTextView.scrollsToTop = scrollsToTop;
    for (UIView* v in self.parentViewController.view.subviews) {
        if ([v respondsToSelector:@selector(scrollView)]) {
            UIScrollView *s = [v performSelector:@selector(scrollView) withObject:nil];
            s.scrollsToTop = !scrollsToTop;
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self setScrollsToTop:NO];

    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)loadLatestWikiTextForSectionFromServer
{
    [self showAlert:@"Loading wiki text..."];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];
    
    DownloadSectionWikiTextOp *downloadWikiTextOp = [[DownloadSectionWikiTextOp alloc] initForPageTitle:section.article.title domain:section.article.domain section:section.index completionBlock:^(NSString *revision){
        
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            [self showAlert:@"Wiki text loaded."];
            [self showAlert:@""];
            self.editTextView.attributedText = [self getAttributedString:revision];
            [self adjustScrollInset];
        }];
        
    } cancelledBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        
    }];
    
    [[QueuesSingleton sharedInstance].sectionWikiTextQ addOperation:downloadWikiTextOp];
}

-(void)adjustScrollInset
{
    // Ensure the edit text view can scroll whatever text it is displaying all the
    // way so the bottom of the text can be scrolled to the top of the screen.
    CGFloat bottomInset = self.view.bounds.size.height - 150;
    self.editTextView.contentInset = UIEdgeInsetsMake(0, 0, bottomInset, 0);
}

- (void)setCursor:(UITextView *)textView
{
    [textView select:self];
    [textView setSelectedRange:NSMakeRange(0, 0)];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [self adjustScrollInset];
}

-(NSAttributedString *)getAttributedString:(NSString *)string
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.maximumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MIN;
    paragraphStyle.minimumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MAX;
    
    return [[NSAttributedString alloc] initWithString: string
                                           attributes: @{
                                                         NSFontAttributeName : [UIFont fontWithName:EDIT_TEXT_VIEW_FONT size:EDIT_TEXT_VIEW_FONT_SIZE],
                                                         NSParagraphStyleAttributeName : paragraphStyle,
                                                         }];
}

- (IBAction)savePushed:(id)sender
{
    [self showAlert:@"Saving..."];
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];

    NSManagedObjectID *articleID = section.article.objectID;

    UploadSectionWikiTextOp *uploadWikiTextOp = [[UploadSectionWikiTextOp alloc] initForPageTitle:section.article.title domain:section.article.domain section:section.index wikiText:self.editTextView.text captchaId:self.captchaId captchaWord:self.captchaTextBox.text completionBlock:^(NSString *result){

        // Mark article for refreshing so its data will be reloaded.
        // (Needs to be done on worker context as worker context changes bubble up through
        // main context too - so web view controller accessing main context will see changes.)
        if (articleID) {
            [articleDataContext_.workerContext performBlockAndWait:^(){
                Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
                if (article) {
                    article.needsRefresh = @YES;
                    NSError *error = nil;
                    [articleDataContext_.workerContext save:&error];
                    NSLog(@"error = %@", error);
                }
            }];
        }
        
        // Cause the web view to reload - now that its sections are gone it will try to reload them.
        UIViewController *vc = self.parentViewController;
        SEL selector = NSSelectorFromString(@"reloadCurrentArticle");
        if ([vc respondsToSelector:selector]) {
            // (Invokes selector in way that doesn't show annoying compiler warning.)
            ((void (*)(id, SEL))[vc methodForSelector:selector])(vc, selector);
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            [self showAlert:result];
            [self showAlert:@""];
            [self performSelector:@selector(hide) withObject:nil afterDelay:1.0f];
        }];
        
    } cancelledBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        
        [self showAlert:errorMsg];

        switch (error.code) {
            case WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA:
                {
                    // If the server said a captcha was required, present the captcha image.
                    NSString *captchaUrl = error.userInfo[@"captchaUrl"];
                    NSString *captchaId = error.userInfo[@"captchaId"];
                    if (articleID) {
                        [articleDataContext_.mainContext performBlockAndWait:^(){
                            Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                            if (article) {
                                self.showCaptchaContainer = YES;
                                [self updateCaptchaContainerConstraint];
                                [UIView animateWithDuration:0.2f animations:^{
                                    [self.view layoutIfNeeded];
                                } completion:^(BOOL done){
                                }];
                                
                                NSURL *captchaImageUrl = [NSURL URLWithString:
                                                          [NSString stringWithFormat:@"https://%@.m.%@%@", article.domain, article.site, captchaUrl]
                                                          ];
                                
                                UIImage *captchaImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:captchaImageUrl]];
                                
                                self.captchaTextBox.text = @"";
                                self.captchaImageView.image = captchaImage;
                                self.captchaId = captchaId;
                            }
                        }];
                    }
                }
                break;
            
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
            case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER:
                {
                    NSString *warningHtml = error.userInfo[@"warning"];
                    //NSLog(@"the warning = %@", warningHtml);

                    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                        [self.captchaTextBox resignFirstResponder];
                        [self.editTextView resignFirstResponder];
                    }];

                    NSString *bannerImage = nil;
                    UIColor *bannerColor = nil;
                    NSString *labelText = nil;
                    UIImage *leftImage = nil;

                    if ((error.code == WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED)) {
                        bannerImage = @"abuse-filter-disallowed.png";
                        bannerColor = [UIColor colorWithRed:0.93 green:0.18 blue:0.20 alpha:1.0];
                        labelText = @"Review edit";
                    }else{
                        bannerImage = @"abuse-filter-flag-white.png";
                        bannerColor = [UIColor colorWithRed:0.99 green:0.32 blue:0.22 alpha:1.0];
                        labelText = @"Ignore or review edit";
                        leftImage = [UIImage imageNamed:@"abuse-filter-check.png"];
                    }

                    NSString *restyledWarningHtml = [self restyleAbuseFilterWarningHtml:warningHtml];
                    [self showAlert:@""];
                    [self showHTMLAlert: restyledWarningHtml
                              leftImage: leftImage
                              labelText: labelText
                             rightImage: [UIImage imageNamed:@"abuse-filter-edit-black.png"]
                            bannerImage: [UIImage imageNamed:bannerImage]
                            bannerColor: bannerColor
                     ];
                }
                break;
 
        default:
            break;
        }
    }];

    [[QueuesSingleton sharedInstance].sectionWikiTextQ addOperation:uploadWikiTextOp];
}

//TODO: this shouldn't be in the controller. Find it a nice home.
-(NSString *)restyleAbuseFilterWarningHtml:(NSString *)warningHtml
{
    // Abuse filter warnings have html :( Re-style as best we can...
    return [NSString stringWithFormat:
        @"\
        <html>\
        <head>\
        <style>\
            *{\
                background-color:transparent!important;\
                border-color:transparent!important;\
                width:auto!important;\
                font:auto!important;\
                font-family:sans-serif!important;\
                font-size:14px!important;\
                color:rgb(85, 85, 85)!important;\
                line-height:22px!important;\
                text-align:left!important;\
            }\
            td[style]{background-color:transparent!important;border-style:none!important;}\
            IMG{zoom:0.5;margin:20px}\
            body{padding:21px!important;padding-top:16px!important;margin:0px!important;}\
        </style>\
        </head>\
        <body>\
        <div>\
            %@\
        </div>\
        </body>\
        </html>\
        ",
    warningHtml];
}

-(void)updateCaptchaContainerConstraint
{
    if (self.editTextViewTopConstraint) {
        [self.view removeConstraint:self.editTextViewTopConstraint];
    }
    
    if (self.showCaptchaContainer) {
        self.editTextViewTopConstraint = [NSLayoutConstraint constraintWithItem: self.editTextView
                                                                      attribute: NSLayoutAttributeTop
                                                                      relatedBy: NSLayoutRelationEqual
                                                                         toItem: self.captchaContainer
                                                                      attribute: NSLayoutAttributeBottom
                                                                     multiplier: 1.0
                                                                       constant: 10];
    }else{
        self.editTextViewTopConstraint = [NSLayoutConstraint constraintWithItem: self.editTextView
                                                                      attribute: NSLayoutAttributeTop
                                                                      relatedBy: NSLayoutRelationEqual
                                                                         toItem: self.cancelButton
                                                                      attribute: NSLayoutAttributeBottom
                                                                     multiplier: 1.0
                                                                       constant: 10];
    }
    
    [self.view addConstraint:self.editTextViewTopConstraint];
}

- (IBAction)reloadCaptchaPushed:(id)sender
{
    // Send a bad captcha response to get a new captcha image.
    self.captchaTextBox.text = @"";
    [self savePushed:nil];
}

- (IBAction)cancelPushed:(id)sender
{
    [self hide];
}

-(void)hide
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    CGFloat distanceScrolled = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);
    if (fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self.editTextView resignFirstResponder];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

@end
