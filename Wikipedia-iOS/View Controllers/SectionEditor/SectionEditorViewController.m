//  Created by Monte Hurd on 1/13/14.

#import "SectionEditorViewController.h"

#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"

#define EDIT_TEXT_VIEW_FONT @"AmericanTypewriter"
#define EDIT_TEXT_VIEW_FONT_SIZE 14.0f
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN 25.0f
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX 25.0f

@interface SectionEditorViewController (){
    ArticleDataContextSingleton *articleDataContext_;
    CGFloat scrollViewDragBeganVerticalOffset_;
}

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

    [self loadLatestWikiTextForSectionFromServer];
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
    Section *section = (Section *)[articleDataContext_.mainContext objectWithID:self.sectionID];
    [section getWikiTextThen:^(NSString *wikiText){

        self.editTextView.attributedText = [self getAttributedString:wikiText];
        [self adjustScrollInset];
        //[self performSelector:@selector(setCursor:) withObject:self.editTextView afterDelay:0.6];
    }];
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
    NSLog(@"save pushed");
}

- (IBAction)cancelPushed:(id)sender
{
    NSLog(@"cancel pushed");
    
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
