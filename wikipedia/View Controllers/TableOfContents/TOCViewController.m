//  Created by Monte Hurd on 12/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TOCViewController.h"
#import "TOCSectionCellView.h"
#import "WebViewController.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "WikipediaAppUtils.h"
#import "Section+LeadSection.h"
#import "Section+TOC.h"
//#import "UIView+Debugging.h"

#define TOC_SELECTION_OFFSET_Y 48.0f
#define TOC_SELECTION_SCROLL_DURATION 0.23
#define TOC_SUBSECTION_INDENT 6

@interface TOCViewController (){

}

@property (strong, nonatomic) NSArray *sectionCells;

@property (strong, nonatomic) UIView *scrollContainer;

@property (strong, nonatomic) NSArray *tocSectionData;

@property (strong, nonatomic) ToCInteractionFunnel *funnel;

@end

@implementation TOCViewController

#pragma mark View lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.tocSectionData = @[];
        self.sectionCells = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.hidden = YES;

    self.funnel = [[ToCInteractionFunnel alloc] init];

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;

    self.scrollContainer = nil;
    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];
    
    // Adjust scrollview content inset when contentSize changes so bottom entry can be scrolled to top.
    [self.scrollView addObserver: self
                      forKeyPath: @"contentSize"
                         options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                         context: nil];

}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self.webVC.webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    return YES;
}

-(void)didHide
{
    [self.funnel logClose];
    
    self.scrollView.scrollsToTop = NO;
    self.webVC.webView.scrollView.scrollsToTop = YES;
    
    self.view.hidden = YES;
}

-(void)willShow
{
    self.view.hidden = NO;
    
    // First set offset to zero - needed if toc opened and devices rotates causing toc
    // to close. If the toc is then opened in new orientation (and the toc had lots of
    // items and one near the end had been selected) it has trouble moving the selected
    // section to the top if offset not zeroed out first.
    self.scrollView.contentOffset = CGPointZero;

    // Ensure cell ancestor views are sized to whatever width the toc happens to be.
    [self.view setNeedsLayout];
    [self.scrollView setNeedsLayout];
    [self.scrollContainer setNeedsLayout];
    [self.view layoutIfNeeded];
    // Ensure the cells are sized to whatever width the toc happens to be.
    [[self.sectionCells copy] makeObjectsPerformSelector:@selector(layoutIfNeeded)];

    // Now move selected item to top.
    [self centerCellForWebViewTopMostSectionAnimated:NO];

    self.scrollView.scrollsToTop = YES;
    self.webVC.webView.scrollView.scrollsToTop = NO;

    [self.funnel logOpen];
}

#pragma mark Refreshing

-(void)refreshForCurrentArticle
{
    //NSLog(@"%f", CACurrentMediaTime() - begin);

    self.scrollView.delegate = nil;

    // Set up the scrollContainer fresh every time!
    [self setupScrollContainer];

    [self setupSectionCells];
    
    for (TOCSectionCellView *cell in [self.sectionCells copy]) {
        [self.scrollContainer addSubview:cell];
    }
    
    // Ensure the scrollContainer is scrolled to the top before its sub-views are constrained.
    self.scrollView.contentOffset = CGPointMake(0, 0);

    [self.view setNeedsUpdateConstraints];
    
    // Don't start monitoring scrollView scrolling until view has appeared.
    self.scrollView.delegate = self;

    //CFTimeInterval begin = CACurrentMediaTime();
}

-(void)setupScrollContainer
{
    if (self.scrollContainer) {
        [self.scrollContainer removeConstraintsOfViewFromView:self.scrollContainer.superview];
        [self.scrollContainer removeFromSuperview];
    }

    self.scrollContainer = [[UIView alloc] init];
    self.scrollContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollContainer.opaque = YES;

    NSDictionary *views = @{@"scrollContainer": self.scrollContainer};
    [self.scrollView addSubview:self.scrollContainer];
    
    [self.scrollContainer.superview addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[scrollContainer]|"
                                             options: 0
                                             metrics: nil
                                               views: views]];

    [self.scrollContainer.superview addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[scrollContainer]|"
                                             options: 0
                                             metrics: nil
                                               views: views]];
    
    // "constant" is -1.0 to ensure the container width never exceeds the scroll view's width.
    // This prevents horizontal scrolling within the toc.
    [self.scrollContainer.superview addConstraint:
     [NSLayoutConstraint constraintWithItem: self.scrollContainer
                                  attribute: NSLayoutAttributeWidth
                                  relatedBy: NSLayoutRelationEqual
                                     toItem: self.scrollContainer.superview
                                  attribute: NSLayoutAttributeWidth
                                 multiplier: 1.0
                                   constant: -(1.0f / [UIScreen mainScreen].scale)]];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    [self constrainSectionCells];
}

-(void)setupSectionCells
{
    NSMutableArray *allCells = @[].mutableCopy;

    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

    for (NSDictionary *sectionData in [self.tocSectionData copy]) {
        
        NSNumber *tag = sectionData[@"id"];
        NSNumber *isLeadNumber = sectionData[@"isLead"];
        BOOL isLead = isLeadNumber.boolValue;
        NSNumber *sectionLevel = sectionData[@"level"];
        id title = sectionData[@"title"];
        
        UIEdgeInsets padding = UIEdgeInsetsZero;
        
        TOCSectionCellView *cell = [[TOCSectionCellView alloc] initWithLevel:sectionLevel.integerValue isLead:isLead isRTL:isRTL];
        
        if (isLead) {
            // Use attributed title only for lead section to add "CONTENTS" text above the title.
            cell.attributedText = title;
            
            CGFloat topPadding = 37;
            CGFloat leadingPadding = 12;
            CGFloat bottomPadding = 14;
            CGFloat trailingPadding = 10;
            
            padding = UIEdgeInsetsMake(topPadding, leadingPadding, bottomPadding, trailingPadding);
            
        }else{
            // Faster to not use attributed string for non-lead sections.
            cell.text = title;
            
            // Indent subsections, but only first 3 levels.
            NSInteger tocLevelToUse = ((sectionLevel.integerValue - 1) < 0) ? 0 : sectionLevel.integerValue - 1;
            tocLevelToUse = MIN(tocLevelToUse, 3);
            CGFloat indent = TOC_SUBSECTION_INDENT;
            indent = 12 + (tocLevelToUse * indent);
            
            CGFloat vPadding = 16;
            CGFloat hPadding = 10;
            
            padding = UIEdgeInsetsMake(vPadding, indent, vPadding, hPadding);
        }
        cell.padding = padding;
        cell.tag = tag.integerValue;
        
        [allCells addObject:cell];
    }
    self.sectionCells = allCells;
}

#pragma mark Hide

-(void)tocTapped:(id)sender
{
    // If tapped, go to section/image selection.
    if ([sender isMemberOfClass:[UITapGestureRecognizer class]]) {
        [self deSelectAllCells];
        [self unHighlightAllCells];
        [self navigateToSelection: sender
                         duration: TOC_SELECTION_SCROLL_DURATION];
        [self.funnel logClick];
    }
}

#pragma mark Navigate

-(void)navigateToSelection: (UITapGestureRecognizer *)tapRecognizer
                  duration: (CGFloat)duration
{
    UIView *view = tapRecognizer.view;
    CGPoint loc = [tapRecognizer locationInView:view];
    UIView *subview = [view hitTest:loc withEvent:nil];
    if ([subview isMemberOfClass:[TOCSectionCellView class]]) {

        [self scrollWebViewToSectionForCell: (TOCSectionCellView *)subview
                                   duration: duration
                                thenHideTOC: YES];
        //NSLog(@"section cell tap index = %ld", (long)subview.tag);

    }else{
        // Hide the toc if non-TOCSectionCellView somehow tapped.
        // NSLog(@"Some other part tapped.");
        [self.webVC tocHide];
    }
}

-(void)scrollWebViewToSectionForCell: (TOCSectionCellView *)cell
                            duration: (CGFloat)duration
                         thenHideTOC: (BOOL)hideTOC
{
    cell.isSelected = YES;
    cell.isHighlighted = YES;

    NSString *elementId = [NSString stringWithFormat:@"section_heading_and_content_block_%ld", (long)cell.tag];

    [self.webVC tocScrollWebViewToSectionWithElementId: elementId
                                              duration: duration
                                           thenHideTOC: hideTOC];
}

#pragma mark Highlight and scroll to focal cell.

-(void)deSelectAllCells
{
    for (TOCSectionCellView *cell in [self.sectionCells copy]) {
        // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
        if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;
        cell.isSelected = NO;
    }
}

-(void)unHighlightAllCells
{
    for (TOCSectionCellView *cell in [self.sectionCells copy]) {
        // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
        if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;
        cell.isHighlighted = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static NSInteger lastOffsetY = 0;
    NSInteger thisOffsetY = (NSInteger)scrollView.contentOffset.y;
    if ((thisOffsetY == lastOffsetY) || (thisOffsetY % 2)) return;
    lastOffsetY = thisOffsetY;

    //BOOL pastFocalCell = NO;

    if (scrollView == self.scrollView) {
        for (TOCSectionCellView *cell in [self.sectionCells copy]) {

            // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
            if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;

            //if (pastFocalCell) {
            //  cell.isHighlighted = NO;
            //}

            if ([self isCellFocalCell:cell]) {
                [self deSelectAllCells];

                //pastFocalCell = YES;
                [self unHighlightAllCells];
                
                cell.isSelected = YES;
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
    CGPoint p = [cell convertPoint: CGPointZero
                            toView: self.scrollView.superview];
    p.x -= self.scrollView.frame.origin.x;
    p.y -= self.scrollView.frame.origin.y;
    if ((p.y < focalOffset) && ((p.y + cell.bounds.size.height) > focalOffset)) {
        if (!cell.isSelected || (cell.isSelected && (cell.tag == 0))) {
            return YES;
        }
    }
    return NO;
}

#pragma mark Scrolling

- (void)scrollViewDidEndDragging: (UIScrollView *)scrollView
                  willDecelerate: (BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    for (TOCSectionCellView *cell in [self.sectionCells copy]) {
        if (cell.isSelected) {

            [self scrollWebViewToSectionForCell: cell
                                       duration: TOC_SELECTION_SCROLL_DURATION
                                    thenHideTOC: NO];
            break;
        }
    }
}

-(void)centerCellForWebViewTopMostSectionAnimated:(BOOL)animated
{
    if (!self.scrollView.isDragging) {
        [self updateHighlightedCellToReflectWebView];
        [self scrollHighlightedCellToSelectionLineWithDuration:(animated ? TOC_SELECTION_SCROLL_DURATION : 0.0f)];
    }
}

#pragma mark Highlighted cell

-(TOCSectionCellView *)getHighlightedCell
{
    for (TOCSectionCellView *cell in [self.sectionCells copy]) {
        if (cell.isSelected) return cell;
    }
    return nil;
}

-(void)scrollHighlightedCellToSelectionLineWithDuration:(CGFloat)duration
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

    [self setScrollViewContentOffset:contentOffset duration:duration];
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
    return view.frame.origin.y - self.scrollView.contentOffset.y /*- [self getSelectionLine]*/;
}

#pragma mark Scroll limits

-(void)setScrollViewContentOffset: (CGPoint)contentOffset
                         duration: (CGFloat)duration
{
        // Setting delegate to nil prevents flicker of TOC selection when scrolling *web
        // view* to new section. Does so by ignoring TOC did scroll events until after
        // TOC finishes scrolling.

    self.scrollView.delegate = nil;
    
    [UIView animateWithDuration: duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{
                         
                         // Not using "setContentOffset:animated:" so duration of animation
                         // can be controlled and action can be taken after animation completes.
                         self.scrollView.contentOffset = contentOffset;
                         
                     } completion:^(BOOL done){
                         
                         self.scrollView.delegate = self;
                         
                     }];
}

-(void)insetToRestrictScrollingTopAndBottomCellsPastCenter
{
    if (!self.scrollContainer || (self.scrollContainer.subviews.count == 0)) return;

    // Make it so the last TOCSectionCellView can't scroll off top of screen.
    // Assumes a TOCSectionCellView cells come at end.
    UIView *lastView = self.scrollContainer.subviews.lastObject;

    // Don't report scrolling when changing inset.
    self.scrollView.delegate = nil;
    CGFloat insetAmount = self.scrollView.bounds.size.height - lastView.bounds.size.height;

    UIEdgeInsets inset = UIEdgeInsetsMake(
        0,
        0,
        insetAmount,
        0
    );
    
    if(!UIEdgeInsetsEqualToEdgeInsets(inset, self.scrollView.contentInset)){
        self.scrollView.contentInset = inset;
    }
    
    self.scrollView.delegate = self;
}

-(void)updateHighlightedCellToReflectWebView
{
    // Highlight cell for section currently nearest top of webview.
    if (self.sectionCells.count > 0){

        [self deSelectAllCells];
        [self unHighlightAllCells];

        NSInteger indexOfFirstOnscreenSection =
        [self.webVC.webView getIndexOfTopOnScreenElementWithPrefix: @"section_heading_and_content_block_"
                                                             count: self.sectionCells.count];
        if (indexOfFirstOnscreenSection < self.sectionCells.count) {
            TOCSectionCellView *cell = ((TOCSectionCellView *)self.sectionCells[indexOfFirstOnscreenSection]);
            cell.isSelected = YES;
            cell.isHighlighted = YES;
        }
    }
}

-(void)observeValueForKeyPath: (NSString *)keyPath
                     ofObject: (id)object
                       change: (NSDictionary *)change
                      context: (void *)context
{
    if (
        (object == self.scrollView)
        &&
        [keyPath isEqual:@"contentSize"]
        ) {
        [self insetToRestrictScrollingTopAndBottomCellsPastCenter];
    }
}

-(void)dealloc
{
    // NSLog(@"tocVC dealloc");

    [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
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
    //CFTimeInterval begin = CACurrentMediaTime();
    if (self.sectionCells.count == 0) return;

    NSLayoutConstraint *(^getConstraint)(UIView *, NSLayoutAttribute, UIView *, NSLayoutAttribute, CGFloat) = ^NSLayoutConstraint *(UIView *view1, NSLayoutAttribute a1, UIView *view2, NSLayoutAttribute a2, CGFloat constant) {
         return [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: view2
                                      attribute: a2
                                     multiplier: 1.0
                                       constant: constant];
    };

    CGFloat scale = (1.0f / [UIScreen mainScreen].scale);
    NSMutableArray *newConstraints = @[].mutableCopy;
    UIView *prevCell = nil;
    for (UIView *cell in [self.sectionCells copy]) {
        [newConstraints addObject:getConstraint(cell, NSLayoutAttributeLeft, self.scrollContainer, NSLayoutAttributeLeft, 0.0f)];
        [newConstraints addObject:getConstraint(cell, NSLayoutAttributeRight, self.scrollContainer, NSLayoutAttributeRight, scale)];
        if (self.sectionCells.firstObject == cell) {
            [newConstraints addObject:getConstraint(cell, NSLayoutAttributeTop, self.scrollContainer, NSLayoutAttributeTop, 0.0f)];
        }
        if (self.sectionCells.lastObject == cell) {
            [newConstraints addObject:getConstraint(cell, NSLayoutAttributeBottom, self.scrollContainer, NSLayoutAttributeBottom, 0.0f)];
        }
        if (prevCell) {
            [newConstraints addObject:getConstraint(cell, NSLayoutAttributeTop, prevCell, NSLayoutAttributeBottom, 0.0f)];
        }
        prevCell = cell;
    }

    if (newConstraints.count > 0) {
        [self.scrollContainer addConstraints:newConstraints];
    }

    //NSLog(@"%f", CACurrentMediaTime() - begin);
}

-(void)setTocSectionDataForSections:(NSSet *)sections
{
    // Keeps self.tocSectionData updated with toc data for the current article.
    // Makes it so the toc data is ready to go as soon as the article is displayed
    // so we don't have to go back though core data to get it when user taps toc
    // button. MUCH faster.
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sectionId" ascending:YES];
    NSArray *sortedSection = [sections sortedArrayUsingDescriptors:@[sort]];

    NSMutableArray *allSectionData = @[].mutableCopy;
    for (Section *section in [sortedSection copy]) {
    
        NSString *title = [section tocTitle];
        if (!section.sectionId || !section.tocLevel || !title) continue;

        NSDictionary *sectionDict =
        @{
          @"id": section.sectionId,
          @"isLead": @([section isLeadSection]),
          @"level": section.tocLevel,
          @"title": title
        };
        
        [allSectionData addObject:sectionDict];

    }
    self.tocSectionData = allSectionData;
    [self refreshForCurrentArticle];
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
