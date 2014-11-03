//  Created by Monte Hurd on 12/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TOCViewController.h"
#import "TOCSectionCellView.h"
#import "WebViewController.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "WikipediaAppUtils.h"
#import "MWKSection+TOC.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"
//#import "UIView+Debugging.h"

#define TOC_SELECTION_OFFSET_Y (48.0f * MENUS_SCALE_MULTIPLIER)
#define TOC_SELECTION_SCROLL_DURATION 0.23
#define TOC_SUBSECTION_INDENT (6.0f * MENUS_SCALE_MULTIPLIER)

@interface TOCViewController (){

}

@property (strong, nonatomic) NSArray *sectionCells;

@property (strong, nonatomic) UIView *scrollContainer;

@property (strong, nonatomic) NSArray *tocSectionData;

@property (strong, nonatomic) ToCInteractionFunnel *funnel;

@end

@implementation TOCViewController

#pragma mark View lifecycle


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // This prevents iOS 6 on old devices from shifting the scrollContainer up after
    // another view controller's view is pushed, then popped, then the TOC shown again.
    // For instance, when edit pencil is tapped then back, then toc button tapped.
    self.scrollView.contentOffset = CGPointZero;
}

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

    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.view.hidden = YES;

    self.funnel = [[ToCInteractionFunnel alloc] init];

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;

    // Add bottom inset so last TOC cell can be scrolled up near top.
    // Otherwise table would restrict it to not being scrolled up past
    // bottom. The "limitVerticalScrolling:" method depends on this.
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 2000, 0);

    self.scrollContainer = nil;
    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];
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

    self.scrollView.delegate = nil;

    // Set up the scrollContainer fresh every time!
    [self setupScrollContainer];

    [self setupSectionCells];
    
    for (TOCSectionCellView *cell in self.sectionCells.copy) {
        [self.scrollContainer addSubview:cell];
    }
    
    // Ensure the scrollContainer is scrolled to the top before its sub-views are constrained.
    self.scrollView.contentOffset = CGPointZero;

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

    // Need to reset the offset mostly for iOS 6 to ensure top TOC section cell doesn't get stuck
    // such that its top half can't be scrolled onscreen. Without this, if you load and article
    // like "Food", then load "Mutual and Balanced Force Reductions" (ie an article with a longer
    // title - so long that it will wrap to more lines than the previous article's title) then
    // quit app, restart, "Mutual and Balanced Force Reductions" should load, now back up to
    // "Food", then go forward to "Mutual and Balanced Force Reductions" again. On an old iOS 6
    // device the top TOC section cell will be stuck - you can't scroll it completely onscreen.
    self.scrollView.contentOffset = CGPointZero;

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
        // We only want to take action when the tap recognizer is in Ended state.
        if (((UITapGestureRecognizer *)sender).state == UIGestureRecognizerStateEnded){
            [self deSelectAllCells];
            [self unHighlightAllCells];
            [self navigateToSelection: sender
                             duration: TOC_SELECTION_SCROLL_DURATION];
            [self.funnel logClick];
        }
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
        
        if ((self.sectionCells.count > 0)) {
            [self limitVerticalScrolling:self.scrollView];
        }
    }
}

-(void)limitVerticalScrolling:(UIScrollView *)scrollView
{
    // Prevents last cell from being scrolled up completely offscreen.
    UIView *lastCell = self.scrollContainer.subviews.lastObject;
    CGRect r = [lastCell.superview convertRect:lastCell.frame toView:self.view];
    if (r.origin.y < 0) {
        [scrollView setContentOffset:CGPointMake(0, lastCell.frame.origin.y) animated:NO];
        return;
    }
    
    // Prevents top of first cell from being scrolled down past screen top.
    // (eliminates top "bounce" - the bounce takes too long imo)
    UIView *firstCell = self.scrollContainer.subviews.firstObject;
    r = [firstCell.superview convertRect:firstCell.frame toView:self.view];
    if (r.origin.y > 0) {
        [scrollView setContentOffset:CGPointMake(0, firstCell.frame.origin.y) animated:NO];
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
    [self scrollViewDidScroll:scrollView];

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

-(void)updateHighlightedCellToReflectWebView
{
    // Highlight cell for section currently nearest top of webview.
    if (self.sectionCells.count > 0){

        [self deSelectAllCells];
        [self unHighlightAllCells];

        NSInteger indexOfFirstOnscreenSection =
        [self.webVC.webView getIndexOfTopOnScreenElementWithPrefix: @"section_heading_and_content_block_"
                                                             count: self.sectionCells.count];

        //NSLog(@"indexOfFirstOnscreenSection = %ld sectionCells.count = %ld", indexOfFirstOnscreenSection, self.sectionCells.count);
        
        // Set to the last cell index if no match.
        // (We may have added extra html at bottom of article at display time.)
        if (indexOfFirstOnscreenSection == -1) {
            indexOfFirstOnscreenSection = self.sectionCells.count - 1;
        }

        if (indexOfFirstOnscreenSection < self.sectionCells.count) {
            TOCSectionCellView *cell = ((TOCSectionCellView *)self.sectionCells[indexOfFirstOnscreenSection]);
            cell.isSelected = YES;
            cell.isHighlighted = YES;
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

-(void)setTocSectionDataForSections:(NSArray *)sections
{
    // Keeps self.tocSectionData updated with toc data for the current article.
    // Makes it so the toc data is ready to go as soon as the article is displayed
    // so we don't have to go back though core data to get it when user taps toc
    // button. MUCH faster.

    NSMutableArray *allSectionData = @[].mutableCopy;
    for (MWKSection *section in [sections copy]) {
    
        NSString *title = [section tocTitle];
        if (!section.sectionId || !section.level || !title) continue;

        NSDictionary *sectionDict =
        @{
          @"id": @(section.sectionId),
          @"isLead": @([section isLeadSection]),
          @"level": section.level,
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
