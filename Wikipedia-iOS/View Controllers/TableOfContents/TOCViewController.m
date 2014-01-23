//  Created by Monte Hurd on 12/26/13.

#import "TOCViewController.h"
#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleCoreDataObjects.h"
#import "Article+Convenience.h"
#import "TOCSectionCellView.h"
#import "WebViewController.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+Debugging.h"
#import "SessionSingleton.h"
#import "ArticleLanguagesTableVC.h"

#define TOC_SECTION_MARGIN (1.0f / [UIScreen mainScreen].scale)
#define TOC_SELECTION_OFFSET_Y 48.0f
#define TOC_DELAY_BETWEEN_SELECTION_AND_ZOOM 0.35f
#define TOC_TAG_OTHER_LANGUAGES 9999

@interface TOCViewController (){

}

// Array of section ids for the current article.
@property (strong, nonatomic) NSMutableArray *sectionIds;

// Dict of sectionImage ids for the current article.
// (key is sectionId, value is array of sectionImage ids)
@property (strong, nonatomic) NSMutableDictionary *sectionImageIds;

@property (strong, nonatomic) NSMutableArray *sectionCells;

@property (strong, nonatomic) NSMutableArray *viewConstraints;

@property (strong, nonatomic) NSNumber *languageCount;

@end

@implementation TOCViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.languageCount = @1;
    self.viewConstraints = [@[] mutableCopy];

    self.sectionIds = [@[]mutableCopy];
    self.sectionImageIds = [@{} mutableCopy];
    self.sectionCells = [@[]mutableCopy];

    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];

    // Get data for sections and section images.
    [self getArticleData];

    // Get cells for section entries in the table of contents.
    [self getSectionCells];
    
    for (UIView *cell in self.sectionCells) {
        [self.scrollContainer addSubview:cell];
    }
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];

    [self constrainScrollContainer];

    self.scrollContainer.backgroundColor = [UIColor clearColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.sectionCells.count == 0) return;
    
    [self updateHighlightedCellToReflectWebView];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self insetToRestrictScrollingTopAndBottomCellsPastCenter];

    // Don't start monitoring scrollView scrolling until view has appeared.
    self.scrollView.delegate = self;

    [self scrollHighlightedCellToSelectionLineAnimated:NO];
    
    //[self.view randomlyColorSubviews];
}

#pragma mark Data retrieval

-(void)getArticleData
{
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    NSString *currentArticleDomain = [SessionSingleton sharedInstance].currentArticleDomain;
    if(currentArticleTitle && currentArticleDomain) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        [articleDataContext_.mainContext performBlockAndWait:^{
            NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: currentArticleTitle
                                                                                          domain: currentArticleDomain];
            if (articleID) {
                Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                if (article) {
          
                    // Get article language count.
                    self.languageCount = article.languagecount;

                    // Get section ids.
                    NSArray *sections = [article getSectionsUsingContext:articleDataContext_.mainContext];
                    for (Section *section in sections) {
                        [self.sectionIds addObject:section.objectID];
                    }
                    // Get section image ids.
                    NSArray *sectionImages = [article getSectionImagesUsingContext:articleDataContext_.mainContext];
                    for (SectionImage *sectionImage in sectionImages) {
                        if (!self.sectionImageIds[sectionImage.section.objectID]) {
                            self.sectionImageIds[sectionImage.section.objectID] = [@[] mutableCopy];
                        }
                        [self.sectionImageIds[sectionImage.section.objectID] addObject:sectionImage.objectID];
                    }
                }
            }
        }];
    }
}

#pragma mark Hide

-(void)tocTapped:(id)sender
{
    // If tapped, go to section/image selection.
    if ([sender isMemberOfClass:[UITapGestureRecognizer class]]) {
        [self unHighlightAllCells];
        [self navigateToSelection:sender];
    }
    [self.webVC performSelector:@selector(tocToggle) withObject:nil afterDelay:TOC_DELAY_BETWEEN_SELECTION_AND_ZOOM];
}

#pragma mark Navigate

-(void)navigateToSelection:(UITapGestureRecognizer *)sender
{
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)sender;
    UIView *view = tapRecognizer.view;
    CGPoint loc = [tapRecognizer locationInView:view];
    UIView *subview = [view hitTest:loc withEvent:nil];

    if ([subview isKindOfClass:[UIImageView class]]) {
        if ([subview.superview isMemberOfClass:[TOCSectionCellView class]]) {
            TOCSectionCellView *cell = (TOCSectionCellView*)subview.superview;
            cell.isHighlighted = YES;
        }

        [self scrollWebViewToImageForCell:(UIImageView *)subview animated:YES];
        //NSLog(@"image tap index = %ld, section index = %ld", (long)subview.tag, (long)subview.superview.tag);

    }else if ([subview isMemberOfClass:[TOCSectionCellView class]]) {

        [self scrollWebViewToSectionForCell:(TOCSectionCellView *)subview animated:YES];
        //NSLog(@"section cell tap index = %ld", (long)subview.tag);

    }
}

-(void)scrollWebViewToSectionForCell:(TOCSectionCellView *)cell animated:(BOOL)animated
{
    cell.isHighlighted = YES;

    NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)cell.tag];
    CGRect r = [self.webVC.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) return;
    CGPoint p = r.origin;

    [self scrollWebView:self.webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebViewToImageForCell:(UIImageView *)imageView animated:(BOOL)animated
{
    NSManagedObjectID *sectionId = self.sectionIds[imageView.superview.tag];
    NSArray *sectionImageIds = self.sectionImageIds[sectionId];
    NSManagedObjectID *sectionImageId = sectionImageIds[imageView.tag];
    
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    SectionImage *sectionImage = (SectionImage *)[articleDataContext_.mainContext objectWithID:sectionImageId];
    
    CGPoint p = [self.webVC.webView getWebViewCoordsForHtmlImageWithSrc:sectionImage.image.sourceUrl];
    p.y = p.y - 23;

    [self scrollWebView:self.webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebView:(UIWebView *)webView toPoint:(CGPoint)point animated:(BOOL)animated
{
    point.x = webView.scrollView.contentOffset.x;
    [webView.scrollView setContentOffset:point animated:animated];
    
    // Give the scrolling a bit of time to finish, then record the new scroll location.
    [self.webVC performSelector:@selector(saveWebViewScrollOffset) withObject:nil afterDelay:0.3];
}

#pragma mark Highlight and scroll to focal cell.

-(void)unHighlightAllCells
{
    for (TOCSectionCellView *cell in self.sectionCells) {
        // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
        if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;
        cell.isHighlighted = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        for (TOCSectionCellView *cell in self.sectionCells) {

            // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
            if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;

//TODO: TOCSectionCellView has a "TODO:" about making a section image object for managing their state. Do that.
// Expecially note the "v.layer.borderColor" stuff below - doesn't belong here.
            [cell resetSectionImageViewsBorderStyle];
            
//TODO: allow this image border highlighting for vertically stacked image layout.
/*
NSArray *centerlineIntersectingCellImages = [cell imagesIntersectingYOffset:focalOffset inView:self.scrollView.superview];
for (UIImageView *v in centerlineIntersectingCellImages) {
    v.layer.borderColor = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:1.0].CGColor;
}
*/
            if ([self isCellFocalCell:cell]) {
                [self unHighlightAllCells];
                cell.isHighlighted = YES;
            }
        }
    }
}

-(BOOL)isCellFocalCell:(TOCSectionCellView *)cell
{
    // "offset" is distance from top of scrollView highlighting starts.
    CGFloat focalOffset = [self getSelectionLine];
    //offset = 0.0f; // <--makes selection window be at top of scrollView
    CGPoint p = [cell convertPoint:CGPointZero toView:self.scrollView.superview];
    p.x -= self.scrollView.frame.origin.x;
    p.y -= self.scrollView.frame.origin.y;
    if ((p.y < focalOffset) && ((p.y + cell.frame.size.height) > focalOffset)) {
        if (!cell.isHighlighted || (cell.isHighlighted && (cell.tag == 0))) {
            return YES;
        }
    }
    return NO;
}

#pragma mark Scroll ended

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    for (TOCSectionCellView *cell in self.sectionCells) {
        if (cell.isHighlighted) {

            CGFloat focalOffset = [self getSelectionLine];
            NSArray *centerlineIntersectingCellImages = [cell imagesIntersectingYOffset:focalOffset inView:self.scrollView.superview];
            
            BOOL shouldAttemptScrollToImage = (centerlineIntersectingCellImages.count > 0) ? YES : NO;
//TODO: enable scroll to image for vertically stacked image layout.
shouldAttemptScrollToImage = NO;
            BOOL shouldAttemptScrollToSection = (!shouldAttemptScrollToImage) ? YES : NO;

            if (shouldAttemptScrollToImage) {
                UIImageView *i = (UIImageView *)centerlineIntersectingCellImages[0];
                    [self scrollWebViewToImageForCell:i animated:YES];
                    break;
            }

            if (shouldAttemptScrollToSection){
                [self scrollWebViewToSectionForCell:cell animated:YES];
                break;
            }
        }
    }
}

-(void)centerCellForWebViewTopMostSection
{
    if (!self.scrollView.isDragging) {
        // Setting delegate to nil prevents flicker of TOC selection when scrolling *web
        // view* to new section. Does so by ignoring TOC did scroll events until after
        // scrollHighlightedCellToSelectionLineAnimated finishes scrolling the TOC.
        self.scrollView.delegate = nil;
        [self updateHighlightedCellToReflectWebView];
        [self scrollHighlightedCellToSelectionLineAnimated:YES];
        [self.scrollView performSelector:@selector(setDelegate:) withObject:self afterDelay:0.3];
    }
}

#pragma mark Constraints

-(void)constrainScrollContainer
{
    [self.scrollContainer.superview addConstraint:
     [NSLayoutConstraint constraintWithItem: self.scrollContainer
                                  attribute: NSLayoutAttributeWidth
                                  relatedBy: NSLayoutRelationEqual
                                     toItem: self.scrollContainer.superview
                                  attribute: NSLayoutAttributeWidth
                                 multiplier: 1.0
                                   constant: 0]];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];

    [self constrainSectionCells];
}

#pragma mark Highlighted cell

-(TOCSectionCellView *)getHighlightedCell
{
    for (TOCSectionCellView *cell in self.sectionCells) {
        if (cell.isHighlighted) return cell;
    }
    return nil;
}

-(void)scrollHighlightedCellToSelectionLineAnimated:(BOOL)animated
{
    if (self.sectionCells.count == 0) return;
    TOCSectionCellView *highlightedCell = [self getHighlightedCell];

    // Return if no cell highlighted.
    if (!highlightedCell) return;

    // Calculate highlighted cell's offset from selection line.
    CGFloat distanceFromCenter = [self offsetFromSelectionLineForView:highlightedCell];

    // Scroll highlighted to selection line (animated).
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y += distanceFromCenter;

    // Ensure the top cell's top isn't below the top of the scroll container.
    contentOffset.y = fmaxf(contentOffset.y, 0);

    [self setScrollViewContentOffset:contentOffset animated:animated];
}

-(CGFloat)getSelectionLine
{
    // Selection line is y coordinate of imaginary horizontal line. TOC cell will be considered selected
    // if it intersects this line.
    return TOC_SELECTION_OFFSET_Y;
}

-(CGFloat)offsetFromSelectionLineForView:(UIView *)view
{
    // Since the selection line is not to far from the top of the page, ignore it for the purpose
    // of scrolling the highlighted cell to the selection line and instead just use an offset that
    // scrolls the section *exactly* to the top of the scroll view container. This keeps a small
    // gap from being left between the top of the screen and the selected cell. Would need to change
    // this to actually take the value from [self getSelectionLine] into account if the selection
    // is ever moved from near the top of the screen.
    return view.frame.origin.y - self.scrollView.contentOffset.y - TOC_SECTION_MARGIN /*- [self getSelectionLine]*/;
}

#pragma mark Scroll limits

-(void)setScrollViewContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
{
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

-(void)insetToRestrictScrollingTopAndBottomCellsPastCenter
{
    // Make it so the last TOCSectionCellView can't scroll off top of screen. Assumes non-TOCSectionCellView cells come at end.
    CGFloat nonTocCellBottomOffset = 0;
    for (UIView *v in [self.sectionCells reverseObjectEnumerator]) {
        nonTocCellBottomOffset += v.frame.size.height + (TOC_SECTION_MARGIN);
        if ([v isMemberOfClass:[TOCSectionCellView class]]) break;
    }
    nonTocCellBottomOffset += (TOC_SECTION_MARGIN);

    // Don't report scrolling when changing inset.
    self.scrollView.delegate = nil;
    self.scrollView.contentInset = UIEdgeInsetsMake(
        0,
        0,
        self.scrollView.frame.size.height - nonTocCellBottomOffset,
        0
    );
    self.scrollView.delegate = self;
}

-(void)updateHighlightedCellToReflectWebView
{
    // Highlight cell for section currently nearest top of webview.
    if (self.sectionCells.count > 0){

        [self unHighlightAllCells];

        NSInteger indexOfFirstOnscreenSection = [self.webVC.webView getIndexOfTopOnScreenElementWithPrefix:@"content_block_" count:self.sectionCells.count];
        if (indexOfFirstOnscreenSection < self.sectionCells.count) {
            ((TOCSectionCellView *)self.sectionCells[indexOfFirstOnscreenSection]).isHighlighted = YES;
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Section cells

-(void)constrainSectionCells
{

//TODO: have these constraints, but also a set which positions cells offscreen, that way
// they can be animated between.

    [self.scrollContainer removeConstraints:self.scrollContainer.constraints];
    
    void (^constrain)(UIView *, NSLayoutAttribute, UIView *, NSLayoutAttribute, CGFloat) = ^void(UIView *view1, NSLayoutAttribute a1, UIView *view2, NSLayoutAttribute a2, CGFloat constant) {
        [self.scrollContainer addConstraint:
         [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: view2
                                      attribute: a2
                                     multiplier: 1.0
                                       constant: constant]];
    };

    UIView *prevCell = nil;
    for (UIView *cell in self.sectionCells) {
        constrain(cell, NSLayoutAttributeLeft, self.scrollContainer, NSLayoutAttributeLeft, 0.0f);
        constrain(cell, NSLayoutAttributeRight, self.scrollContainer, NSLayoutAttributeRight, 0.0f);
        if (self.sectionCells.firstObject == cell) {
            constrain(cell, NSLayoutAttributeTop, self.scrollContainer, NSLayoutAttributeTop, TOC_SECTION_MARGIN);
        }else if (self.sectionCells.lastObject == cell) {
            constrain(cell, NSLayoutAttributeBottom, self.scrollContainer, NSLayoutAttributeBottom, -TOC_SECTION_MARGIN);
        }
        if (prevCell) {
            constrain(cell, NSLayoutAttributeTop, prevCell, NSLayoutAttributeBottom, TOC_SECTION_MARGIN);
        }
        prevCell = cell;
    }
}

-(void)getSectionCells
{
    for (NSManagedObjectID *sectionId in self.sectionIds) {
        TOCSectionCellView *cell = [[TOCSectionCellView alloc] init];
        cell.translatesAutoresizingMaskIntoConstraints = NO;
        cell.sectionImageIds = self.sectionImageIds[sectionId];
        cell.sectionId = sectionId;
        [self.sectionCells addObject:cell];
    }
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
