//  Created by Monte Hurd on 12/26/13.

#import "TOCViewController.h"
#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleCoreDataObjects.h"
#import "Article+Convenience.h"
#import "TOCSectionCellView.h"
#import "WebViewController.h"
#import "UIWebView+ElementLocation.h"

#define TOC_SECTION_MARGIN 0.0f

@interface TOCViewController (){

}

// Array of section ids for the current article.
@property (strong, nonatomic) NSMutableArray *sectionIds;

// Dict of sectionImage ids for the current article.
// (key is sectionId, value is array of sectionImage ids)
@property (strong, nonatomic) NSMutableDictionary *sectionImageIds;

@property (strong, nonatomic) NSMutableArray *sectionCells;

@property (nonatomic) BOOL animateWebScrollAsFocalCellChanges;

@end

@implementation TOCViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // If this is YES the focal cell's selection will be scrolled to when the TOC stops sliding.
    // If this is NO the focal cell's section will be jumped to as soon as cell becomes focal.
    self.animateWebScrollAsFocalCellChanges = NO;
 
    self.sectionIds = [@[]mutableCopy];
    self.sectionImageIds = [@{} mutableCopy];
    self.sectionCells = [@[]mutableCopy];

    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];

    // Get data for sections and section images.
    [self getSectionIds];
    [self getSectionImageIds];
 
    [self getSectionCells];

    for (TOCSectionCellView *cell in self.sectionCells) {
        [self.scrollContainer addSubview:cell];
    }
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideTOC) name:@"SearchFieldBecameFirstResponder" object:nil];
    
    [self constrainScrollContainer];

    self.scrollContainer.backgroundColor = [UIColor clearColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //WebViewController *webVC = (WebViewController *)self.parentViewController;

//TODO: Need to remove and reset these web view animations on rotate before using them.
/*
 Have the web view controller do this after rotate conditionally if it sees these animations
 are in effect - for it to do this the shrinkReset and skewReset methods would need to
 remove animations for keys WEBVIEW_SHRINK and WEBVIEW_SKEW once they finish resetting.
 This way the webVC can know if either of these animations are in effect by just looking
 for animations for these keys.
*/
    //[webVC shrinkAndAlignRightWithScale:0.6f];
    //[webVC skewWithEyePosition:-2000.0f angle:7.5f];

    if (self.sectionCells.count == 0) return;
    
    // Temporarily set content insets to allow top cell to be completely off bottom of screen.
    [self insetToRestrictScrollingToHeight:@(self.scrollView.frame.size.height)];

    // Move all cells just off bottom of screen.
    [self setScrollViewContentOffset:CGPointMake(0.0f, -self.scrollView.frame.size.height)];

    [self updateHighlightedCellToReflectWebView];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    //WebViewController *webVC = (WebViewController *)self.parentViewController;
    //[webVC shrinkReset];
    //[webVC skewReset];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self scrollHighlightedCellToScreenCenter];
    [self cascadeSectionCellsAlphaFromMiddle];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Don't start monitoring scrollView scrolling until view has appeared.
    self.scrollView.delegate = self;

    [self scrollHighlightedCellToScreenCenter];

    [self cascadeSectionCellsAlphaFromMiddle];
}

#pragma mark Data retrieval

//TODO: these 2 methods have a lot in common... refactor and stuff.

-(void) getSectionIds
{
    NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];
    if(lastViewedArticleTitle) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        [articleDataContext_.workerContext performBlockAndWait:^{
            NSManagedObjectID *articleID = [articleDataContext_.workerContext getArticleIDForTitle:lastViewedArticleTitle];
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            if (article) {
                NSArray *sections = [article getSectionsUsingContext:articleDataContext_.workerContext];
                for (Section *section in sections) {
                    [self.sectionIds addObject:section.objectID];
                }
            }
        }];
    }
}

-(void) getSectionImageIds
{
    NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];
    if(lastViewedArticleTitle) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        [articleDataContext_.workerContext performBlockAndWait:^{
            NSManagedObjectID *articleID = [articleDataContext_.workerContext getArticleIDForTitle:lastViewedArticleTitle];
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            if (article) {
                NSArray *sectionImages = [article getSectionImagesUsingContext:articleDataContext_.workerContext];
                for (SectionImage *sectionImage in sectionImages) {
                    if (!self.sectionImageIds[sectionImage.section.objectID]) {
                        self.sectionImageIds[sectionImage.section.objectID] = [@[] mutableCopy];
                    }
                    [self.sectionImageIds[sectionImage.section.objectID] addObject:sectionImage.objectID];
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

    [self performSelector:@selector(hideTOC) withObject:nil afterDelay:0.15f];
}

-(void)hideTOC
{
    WebViewController *webVC = (WebViewController *)self.parentViewController;
    [webVC tocToggle];
}

#pragma mark Navigate

-(void)navigateToSelection:(UITapGestureRecognizer *)sender
{
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)sender;
    UIView *view = tapRecognizer.view;
    CGPoint loc = [tapRecognizer locationInView:view];
    UIView *subview = [view hitTest:loc withEvent:nil];

    if ([subview isMemberOfClass:[UIImageView class]]) {
        if ([subview.superview isMemberOfClass:[TOCSectionCellView class]]) {
            TOCSectionCellView *cell = (TOCSectionCellView*)subview.superview;
            cell.isHighlighted = YES;
        }

        [self scrollWebViewToImageForCell:(UIImageView *)subview animated:NO];
        //NSLog(@"image tap index = %ld, section index = %ld", (long)subview.tag, (long)subview.superview.tag);
    }else if ([subview isMemberOfClass:[TOCSectionCellView class]]) {
        [self scrollWebViewToSectionForCell:(TOCSectionCellView *)subview animated:NO];
        //NSLog(@"section cell tap index = %ld", (long)subview.tag);
    }
}

-(void)scrollWebViewToSectionForCell:(TOCSectionCellView *)cell animated:(BOOL)animated
{
    cell.isHighlighted = YES;

    WebViewController *webVC = (WebViewController *)self.parentViewController;
    NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)cell.tag];
    CGPoint p = [webVC.webView getWebViewRectForHtmlElementWithId:elementId].origin;

    [self scrollWebView:webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebViewToImageForCell:(UIImageView *)imageView animated:(BOOL)animated
{
    NSManagedObjectID *sectionId = self.sectionIds[imageView.superview.tag];
    NSArray *sectionImageIds = self.sectionImageIds[sectionId];
    NSManagedObjectID *sectionImageId = sectionImageIds[imageView.tag];
    
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    SectionImage *sectionImage = (SectionImage *)[articleDataContext_.mainContext objectWithID:sectionImageId];
    
    WebViewController *webVC = (WebViewController *)self.parentViewController;
    CGPoint p = [webVC.webView getWebViewCoordsForHtmlImageWithSrc:sectionImage.image.sourceUrl];
    p.y = p.y - 23;

    [self scrollWebView:webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebView:(UIWebView *)webView toPoint:(CGPoint)point animated:(BOOL)animated
{
    point.x = webView.scrollView.contentOffset.x;
    [webView.scrollView setContentOffset:point animated:animated];
}

#pragma mark Highlight and scroll to focal cell.

-(void)unHighlightAllCells
{
    for (TOCSectionCellView *cell2 in self.sectionCells) {
        cell2.isHighlighted = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        CGFloat focalOffset = self.scrollView.frame.size.height / 2.0f;
        for (TOCSectionCellView *cell in self.sectionCells) {

//TODO: TOCSectionCellView has a "TODO:" about making a section image object for managing their state. Do that.
// Expecially note the "v.layer.borderColor" stuff below - doesn't belong here.
            [cell resetSectionImageViewsBorderStyle];
            NSArray *centerlineIntersectingCellImages = [cell imagesIntersectingYOffset:focalOffset inView:self.scrollView.superview];
            
//TODO: allow this image border highlighting for vertically stacked image layout.
/*
            for (UIImageView *v in centerlineIntersectingCellImages) {
                v.layer.borderColor = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:1.0].CGColor;
            }
*/
            if ([self isCellFocalCell:cell]) {
                [self unHighlightAllCells];
                cell.isHighlighted = YES;
            }

            BOOL shouldAttemptScrollToImage = (centerlineIntersectingCellImages.count > 0) ? YES : NO;
            BOOL shouldAttemptScrollToSection = ((!shouldAttemptScrollToImage) && cell.isHighlighted) ? YES : NO;

//TODO: allow "shouldAttemptScrollToImage" to be used for vertically stacked image layout.
shouldAttemptScrollToImage = NO;

            /*
             // Probably never do this here - to much "bridge" traffic for each scroll pixel move...
             WebViewController *webVC = (WebViewController *)self.parentViewController;
             NSInteger indexOfFirstOnscreenSection = [webVC.webView getIndexOfTopOnScreenElementWithPrefix:@"content_block_" count:self.sectionCells.count];
             NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)indexOfFirstOnscreenSection];
             CGPoint p = [webVC.webView getWebViewRectForHtmlElementWithId:elementId].origin;
             if ((p.y < 0) || (p.y > 100)) shouldAttemptScrollToSection = YES;
             */
            
            if (shouldAttemptScrollToImage) {
                UIImageView *i = (UIImageView *)centerlineIntersectingCellImages[0];
                    [self scrollWebViewToImageForCell:i animated:NO];
            }

            if (shouldAttemptScrollToSection){
                if (!self.animateWebScrollAsFocalCellChanges) {
                        [self scrollWebViewToSectionForCell:cell animated:NO];
                }
            }
        }
    }
    [self cascadeSectionCellsAlphaFromMiddle];
}

-(void)cascadeSectionCellsAlphaFromMiddle
{

//TODO: the layout with the large vertically stacked images should *not* cascasde cell alpha.
//return;

    CGFloat minAlpha = 0.25f;

    //CGFloat whiteLevel = 0.0f;
    CGFloat halfContainerHeight = self.scrollView.frame.size.height / 2.0f;
    // Proportionately fade out cells around middle cell.
    for (TOCSectionCellView *cell in self.sectionCells) {
//      if (cell.isHighlighted) continue;

        //if (self.sectionCells.firstObject != cell) continue;
        //if (self.sectionCells.lastObject != cell) continue;

        CGFloat distanceFromCenter = [self offsetFromCenterForView:cell];

        //if (distanceFromCenter < 0) distanceFromCenter *= 1.5;

        CGFloat alpha = fabsf((fabsf(distanceFromCenter) - halfContainerHeight) / halfContainerHeight);
        //alpha = 1.0f - alpha; // Inverts alpha.
        alpha = MAX(alpha, minAlpha);
        
        if(fabsf(distanceFromCenter) > halfContainerHeight) alpha = minAlpha;
        
        cell.alpha = alpha;
        //cell.backgroundColor = [UIColor colorWithWhite:whiteLevel alpha:alpha];
    }
}

-(BOOL)isCellFocalCell:(TOCSectionCellView *)cell
{
    // "offset" is distance from top of scrollView highlighting starts.
    CGFloat focalOffset = self.scrollView.frame.size.height / 2.0f;
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

#pragma mark Scroll if self.animateWebScrollAsFocalCellChanges == YES

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    if (!self.animateWebScrollAsFocalCellChanges) return;
    for (TOCSectionCellView *cell in self.sectionCells) {
        if (cell.isHighlighted) {
            [self scrollWebViewToSectionForCell:cell animated:YES];
            break;
        }
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

    [self constrainTOCView];
}

- (void)constrainTOCView
{
    float margin = 0.0f;
    void (^constrain)(NSLayoutAttribute, float) = ^void(NSLayoutAttribute a, float constant) {
        [self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                                        attribute:a
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view.superview
                                                                        attribute:a
                                                                       multiplier:1.0
                                                                         constant:constant]];
    };
    
    constrain(NSLayoutAttributeLeft, margin);
    constrain(NSLayoutAttributeRight, -margin);
    constrain(NSLayoutAttributeTop, margin);
    constrain(NSLayoutAttributeBottom, -margin);
}

#pragma mark Highlighted cell

-(TOCSectionCellView *)getHighlightedCell
{
    for (TOCSectionCellView *cell in self.sectionCells) {
        if (cell.isHighlighted) return cell;
    }
    return nil;
}

-(void)scrollHighlightedCellToScreenCenter
{
    if (self.sectionCells.count == 0) return;
    TOCSectionCellView *highlightedCell = [self getHighlightedCell];

    // Return if no cell highlighted.
    if (!highlightedCell) return;

    // Temporarily set content insets to allow top cell to be completely off bottom of screen.
    [self insetToRestrictScrollingToHeight:@(self.scrollView.frame.size.height)];

    // Calculate highlighted cell's offset from screen center.
    CGFloat distanceFromCenter = [self offsetFromCenterForView:highlightedCell];

    // Scroll highlighted to screen center (animated).
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y += distanceFromCenter;
    
    //NSLog(@"contentOffset.y = %f", contentOffset.y);
    [self setScrollViewContentOffset:contentOffset];

    // After delay (to allow animated scroll above to complete) reset content
    // insets to prevent first and last cells from scrolling past screen center.
    [self performSelector:@selector(insetToRestrictScrollingTopAndBottomCellsPastCenter) withObject:nil afterDelay:0.35f];
}

-(CGFloat)offsetFromCenterForView:(UIView *)view
{
    return view.center.y - self.scrollView.contentOffset.y - self.scrollView.frame.size.height / 2.0f;
}

#pragma mark Scroll limits

-(void)insetToRestrictScrollingToHeight:(NSNumber *)height
{
    // Don't report scrolling when changing inset.
    self.scrollView.delegate = nil;

    self.scrollView.contentInset = UIEdgeInsetsMake(
        height.floatValue - TOC_SECTION_MARGIN,
        0,
        height.floatValue - TOC_SECTION_MARGIN,
        0
    );
    self.scrollView.delegate = self;
}

-(void)setScrollViewContentOffset:(CGPoint)contentOffset
{
    // Don't report scrolling when changing offset.
    self.scrollView.delegate = nil;
    [self.scrollView setContentOffset:contentOffset animated:NO];
    self.scrollView.delegate = self;
}

-(void)insetToRestrictScrollingTopAndBottomCellsPastCenter
{
    // Don't report scrolling when changing inset.
    self.scrollView.delegate = nil;
    CGFloat halfHeight = self.scrollView.frame.size.height / 2.0f;

//TODO: the vertially stacked image layout should do "insetToRestrictScrollingToHeight", but the default layout
// should not. Presently both are using "insetToRestrictScrollingToHeight" because of the line below.
[self insetToRestrictScrollingToHeight:@(halfHeight)];
return;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(
        halfHeight - TOC_SECTION_MARGIN - (((UIView *)self.sectionCells.firstObject).frame.size.height / 2.0f),
        0,
        halfHeight - TOC_SECTION_MARGIN - (((UIView *)self.sectionCells.lastObject).frame.size.height / 2.0f),
        0
    );
    self.scrollView.delegate = self;
}

-(void)updateHighlightedCellToReflectWebView
{
    // Highlight cell for section currently nearest top of webview.
    if (self.sectionCells.count > 0){
        [self unHighlightAllCells];
        WebViewController *webVC = (WebViewController *)self.parentViewController;
        NSInteger indexOfFirstOnscreenSection = [webVC.webView getIndexOfTopOnScreenElementWithPrefix:@"content_block_" count:self.sectionCells.count];
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

    CGFloat margin = TOC_SECTION_MARGIN / [UIScreen mainScreen].scale;
    //margin = 0.0f;
    TOCSectionCellView *prevCell = nil;
    for (TOCSectionCellView *cell in self.sectionCells) {
        constrain(cell, NSLayoutAttributeLeft, self.scrollContainer, NSLayoutAttributeLeft, margin);
        constrain(cell, NSLayoutAttributeRight, self.scrollContainer, NSLayoutAttributeRight, -margin);
        if (self.sectionCells.firstObject == cell) {
            constrain(cell, NSLayoutAttributeTop, self.scrollContainer, NSLayoutAttributeTop, margin);
        }else if (self.sectionCells.lastObject == cell) {
            constrain(cell, NSLayoutAttributeBottom, self.scrollContainer, NSLayoutAttributeBottom, -margin);
        }
        if (prevCell) {
            constrain(cell, NSLayoutAttributeTop, prevCell, NSLayoutAttributeBottom, margin);
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
