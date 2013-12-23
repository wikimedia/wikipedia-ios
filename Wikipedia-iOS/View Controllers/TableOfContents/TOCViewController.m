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
    self.animateWebScrollAsFocalCellChanges = YES;
 
    self.sectionIds = [@[]mutableCopy];
    self.sectionImageIds = [@{} mutableCopy];
    self.sectionCells = [@[]mutableCopy];

    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];

    self.scrollView.delegate = self;

    // Get data for sections and section images.
    [self getSectionIds];
    [self getSectionImageIds];
 
    [self getSectionCells];

    for (TOCSectionCellView *cell in self.sectionCells) {
        [self.scrollContainer addSubview:cell];
    }
    
    [self constrainSectionCells];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideTOC) name:@"SearchFieldBecameFirstResponder" object:nil];
    
    [self constrainScrollContainer];

    self.scrollContainer.backgroundColor = [UIColor clearColor];
}

#pragma mark Constrain scroll container

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

#pragma mark Data retrieval

//TODO: these 2 methods have a lot in common...

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

-(void)hideScrollingOffScreenBottom
{
    CGPoint p = CGPointMake(0.0f, -self.scrollView.frame.size.height);
    [self.scrollView setContentOffset:p animated:YES];
}

-(void)hideTOC
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

#pragma mark Navigate

-(void)navigateToSelection:(UITapGestureRecognizer *)sender
{
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)sender;
    UIView *view = tapRecognizer.view;
    CGPoint loc = [tapRecognizer locationInView:view];
    UIView *subview = [view hitTest:loc withEvent:nil];
    if ([subview isMemberOfClass:[UIImageView class]]) {
        [self scrollWebViewToImageForCell:(UIImageView *)subview animated:YES];
        //NSLog(@"image tap index = %ld, section index = %ld", (long)subview.tag, (long)subview.superview.tag);
    }else if ([subview isMemberOfClass:[TOCSectionCellView class]]) {
        [self scrollWebViewToSectionForCell:(TOCSectionCellView *)subview animated:YES];
        //NSLog(@"section cell tap index = %ld", (long)subview.tag);
    }
}

-(void)scrollWebViewToSectionForCell:(TOCSectionCellView *)cell animated:(BOOL)animated
{
    cell.isSelected = YES;
    cell.isHighlighted = YES;

    WebViewController *webVC = (WebViewController *)self.parentViewController;
    NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)cell.tag];
    CGPoint p = [webVC.webView getWebViewRectForHtmlElementWithId:elementId].origin;
    [self scrollWebView:webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebViewToImageForCell:(UIImageView *)imageView animated:(BOOL)animated
{

if ([imageView.superview isMemberOfClass:[TOCSectionCellView class]]) {
    TOCSectionCellView *cell = (TOCSectionCellView*)imageView.superview;
    cell.isSelected = YES;
    cell.isHighlighted = YES;
}

    NSManagedObjectID *sectionId = self.sectionIds[imageView.superview.tag];
    NSArray *sectionImageIds = self.sectionImageIds[sectionId];
    NSManagedObjectID *sectionImageId = sectionImageIds[imageView.tag];
    
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    SectionImage *sectionImage = (SectionImage *)[articleDataContext_.mainContext objectWithID:sectionImageId];
    
    WebViewController *webVC = (WebViewController *)self.parentViewController;
    CGPoint p = [webVC.webView getWebViewCoordsForHtmlImageWithSrc:sectionImage.image.sourceUrl];
    [self scrollWebView:webVC.webView toPoint:p animated:animated];
}

-(void)scrollWebView:(UIWebView *)webView toPoint:(CGPoint)point animated:(BOOL)animated
{
    point.x = webView.scrollView.contentOffset.x;
    point.y = point.y - 23;
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
    static CGFloat lastHighlightedCellTag = 0;
    if (scrollView == self.scrollView) {
        for (TOCSectionCellView *cell in self.sectionCells) {
            if ([self isCellFocalCell:cell]) {
                [self unHighlightAllCells];
                cell.isHighlighted = YES;
                lastHighlightedCellTag = cell.tag;
                if (!self.animateWebScrollAsFocalCellChanges) {
                    [self scrollWebViewToSectionForCell:cell animated:NO];
                }
            }else{
                if (lastHighlightedCellTag == cell.tag) continue;
                cell.isHighlighted = NO;
            }
        }
    }
    
    [self cascadeSectionCellsAlphaFromMiddle];
}

-(void)cascadeSectionCellsAlphaFromMiddle
{
    CGFloat minAlpha = 0.25f;
    //CGFloat whiteLevel = 0.0f;
    CGFloat halfContainerHeight = self.scrollView.frame.size.height / 2.0f;
    // Proportionately fade out cells around middle cell.
    for (TOCSectionCellView *cell in self.sectionCells) {
        if (cell.isHighlighted) continue;

        //if (self.sectionCells.firstObject != cell) continue;
        //if (self.sectionCells.lastObject != cell) continue;

        CGFloat distanceFromCenter = cell.center.y - self.scrollView.contentOffset.y - halfContainerHeight;

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
        if (!cell.isHighlighted) {
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

#pragma mark Resize with parent view controller

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];

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
    
    [self updateScrollContentInset];
    
    [self revealFromBottomToMidScreen];
}

-(void)revealFromBottomToMidScreen
{
    if (self.sectionCells.count == 0) return;
    UIView *firstCell = (UIView *)[self.sectionCells firstObject];
    
    // First move just off bottom of screen.
    CGPoint p = CGPointMake(0.0f, -self.scrollView.frame.size.height);
    [self.scrollView setContentOffset:p animated:NO];

    // Now scroll up to just below center of screen.
    CGPoint p2 = CGPointMake(
                            0.0f,
                            -(self.scrollView.contentInset.top + firstCell.frame.size.height) / 2.0f
                            );
    [self.scrollView setContentOffset:p2 animated:YES];
}

- (void)viewDidLayoutSubviews
{
    [self updateScrollContentInset];
}

-(void)updateScrollContentInset
{
    // Allows the scrollview to scroll the bottom cell all the way to the top and top all the way to bottom.
    if (self.sectionCells.count > 0) {
        UIView *lastCell = (UIView *)[self.sectionCells lastObject];
        UIView *firstCell = (UIView *)[self.sectionCells firstObject];
        CGFloat f = self.scrollView.frame.size.height - firstCell.frame.size.height;
        f -= TOC_SECTION_MARGIN;
        CGFloat l = self.scrollView.frame.size.height - lastCell.frame.size.height;
        l -= TOC_SECTION_MARGIN;
        self.scrollView.contentInset = UIEdgeInsetsMake(f, 0, l, 0);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)constrainSectionCells
{

//TODO: have these constrains, but also a set which positions cells offscreen, that way
// they can be animated between.

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

-(NSString *)getSectionsWithImageDebuggingString
{
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    NSMutableArray *tempTocArray = [@[]mutableCopy];
    
    for (NSManagedObjectID *sectionId in self.sectionIds) {
        
        Section *section = (Section *)[articleDataContext_.workerContext objectWithID:sectionId];
        
        NSString *tabs = [@"" stringByPaddingToLength:section.tocLevel.integerValue withString:@"\t" startingAtIndex:0];
        
        NSArray *sectionImageIds = self.sectionImageIds[sectionId];
        
        NSMutableArray *imgStrArray = [@[]mutableCopy];
        for (NSManagedObjectID *sectionImageId in sectionImageIds) {
            SectionImage *sectionImage = (SectionImage *)[articleDataContext_.workerContext objectWithID:sectionImageId];
            [imgStrArray addObject:[NSString stringWithFormat:@"%@\t*%@", tabs, sectionImage.image.fileName]];
        }
        
        NSString *sectionString = [NSString stringWithFormat:@"%@%@-%@: %@\n%@\n",
                                   tabs,
                                   section.index,
                                   section.tocLevel,
                                   section.title,
                                   [imgStrArray componentsJoinedByString:@"\n"]
                                   ];
        [tempTocArray addObject:sectionString];
    }
    
    return [tempTocArray componentsJoinedByString:@"\n"];
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
