//  Created by Monte Hurd on 12/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

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
#import "UIView+RemoveConstraints.h"
#import "WikipediaAppUtils.h"
#import "Section+LeadSection.h"
#import "NSString+FormattedAttributedString.h"
#import "NSString+Extras.h"

#define TOC_SECTION_MARGIN 0 //(1.0f / [UIScreen mainScreen].scale)
#define TOC_SELECTION_OFFSET_Y 48.0f
#define TOC_DELAY_BETWEEN_SELECTION_AND_ZOOM 0.35f
#define TOC_TAG_OTHER_LANGUAGES 9999

#define TOC_SELECTION_SCROLL_DURATION 0.2

#define TOC_SUBSECTION_INDENT 6 //15

@interface TOCViewController (){

}

@property (strong, nonatomic) NSMutableArray *sectionCells;

@property (strong, nonatomic) IBOutlet UIView *scrollContainer;

@end

@implementation TOCViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.funnel = [[ToCInteractionFunnel alloc] init];

    self.sectionCells = @[].mutableCopy;

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;

    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.navigationItem.hidesBackButton = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tocTapped:)];
    [self.view addGestureRecognizer:tap];

    [self constrainScrollContainerWidth];
    
    self.scrollContainer.translatesAutoresizingMaskIntoConstraints = NO;

    self.scrollContainer.backgroundColor = [UIColor clearColor];

    self.scrollView.scrollsToTop = NO;
    
    // Adjust scrollview content inset when contentSize changes so bottom entry can be scrolled to top.
    [self.scrollView addObserver: self
                      forKeyPath: @"contentSize"
                         options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                         context: nil];

    [self refreshForCurrentArticle];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.funnel logClose];

    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.funnel logOpen];
}

#pragma mark Refreshing

-(void)refreshForCurrentArticle
{
    self.scrollView.delegate = nil;

    [self.scrollContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    [self.sectionCells removeAllObjects];

    [self setupSectionCells];

    for (TOCSectionCellView *cell in self.sectionCells) {
        [self.scrollContainer addSubview:cell];
    }

    if (self.sectionCells.count == 0) return;
    
    // Don't start monitoring scrollView scrolling until view has appeared.
    self.scrollView.delegate = self;
}

-(void)setupSectionCells
{
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    NSString *currentArticleDomain = [SessionSingleton sharedInstance].currentArticleDomain;
    if(currentArticleTitle && currentArticleDomain) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        [articleDataContext_.mainContext performBlockAndWait:^{
            NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: currentArticleTitle
                                                                                          domain: currentArticleDomain];

            BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

            if (articleID) {
                Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                if (article) {
                    // Get section ids.
                    NSArray *sections = [article getSectionsUsingContext:articleDataContext_.mainContext];
                    for (Section *section in sections) {
                        
                        NSNumber *tag = section.sectionId;
                        NSNumber *isLead = @([section isLeadSection]);
                        NSNumber *sectionLevel = section.tocLevel;
                        id title = [self getTitleForSection:section];
                        UIEdgeInsets padding = UIEdgeInsetsZero;
                        
                        TOCSectionCellView *cell = [[TOCSectionCellView alloc] initWithLevel:sectionLevel.integerValue isLead:isLead.boolValue isRTL:isRTL];
                        
                        if (isLead.boolValue) {
                            // Use attributed title only for lead section to add "CONTENTS" text above the title.
                            cell.attributedText = title;

                            CGFloat topPadding = 37;
                            CGFloat leadingPadding = 12;
                            CGFloat bottomPadding = 14;
                            CGFloat trailingPadding = 10;
                            if (!isRTL) {
                                padding = UIEdgeInsetsMake(topPadding, leadingPadding, bottomPadding, trailingPadding);
                            }else{
                                padding = UIEdgeInsetsMake(topPadding, trailingPadding, bottomPadding, leadingPadding);
                            }
                            
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
                            if (!isRTL) {
                                padding = UIEdgeInsetsMake(vPadding, indent, vPadding, hPadding);
                            }else{
                                padding = UIEdgeInsetsMake(vPadding, hPadding, vPadding, indent);
                            }

                        }
                        cell.padding = padding;
                        cell.tag = tag.integerValue;
                        
                        [self.sectionCells addObject:cell];
                    }
                }
            }
        }];
    }
}

-(id)getTitleForSection:(Section *)section
{
    NSString *title = [section isLeadSection] ? section.article.title : section.title;
    NSString *noHtmlTitle = [title getStringWithoutHTML];
    id titleToUse = [section isLeadSection] ? [self getLeadSectionAttributedTitleForString:noHtmlTitle] : noHtmlTitle;
    return titleToUse;
}

-(NSAttributedString *)getLeadSectionAttributedTitleForString:(NSString *)string
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8;
    
    NSDictionary *contentsHeaderAttributes = @{
                                    NSFontAttributeName : [UIFont boldSystemFontOfSize:10.5],
                                    NSKernAttributeName : @(1.25),
                                    NSParagraphStyleAttributeName : paragraphStyle
                                    };
    NSDictionary *sectionTitleAttributes = @{
                                       NSFontAttributeName : [UIFont fontWithName:@"Times New Roman" size:24]
                                       };
    
    NSString *heading = MWLocalizedString(@"table-of-contents-heading", nil);
    
    if ([[SessionSingleton sharedInstance].domain isEqualToString:@"en"]) {
        heading = [heading uppercaseString];
    }
    
    return [@"$1\n$2" attributedStringWithAttributes: @{}
                                 substitutionStrings: @[heading, string]
                              substitutionAttributes: @[contentsHeaderAttributes, sectionTitleAttributes]
            ];
    
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
    for (TOCSectionCellView *cell in self.sectionCells) {
        // In case other non-TOCSectionCellView views are tacked beneath the TOCSectionCellView's...
        if (![cell isMemberOfClass:[TOCSectionCellView class]]) continue;
        cell.isSelected = NO;
    }
}

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
    static NSInteger lastOffsetY = 0;
    NSInteger thisOffsetY = (NSInteger)scrollView.contentOffset.y;
    if ((thisOffsetY == lastOffsetY) || (thisOffsetY % 2)) return;
    lastOffsetY = thisOffsetY;

    //BOOL pastFocalCell = NO;

    if (scrollView == self.scrollView) {
        for (TOCSectionCellView *cell in self.sectionCells) {

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
    for (TOCSectionCellView *cell in self.sectionCells) {
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
        [self scrollHighlightedCellToSelectionLineWithDuration:(animated ? 0.2f : 0.0f)];
    }
}

#pragma mark Constraints

-(void)constrainScrollContainerWidth
{
    [self.scrollContainer.superview addConstraint:
     [NSLayoutConstraint constraintWithItem: self.scrollContainer
                                  attribute: NSLayoutAttributeWidth
                                  relatedBy: NSLayoutRelationEqual
                                     toItem: self.scrollContainer.superview
                                  attribute: NSLayoutAttributeWidth
                                 multiplier: 1.0
                                   constant: -(1.0f / [UIScreen mainScreen].scale)]];
    // "constant" is -1.0 to ensure the container width never exceeds the scroll view's width.
    // This prevents horizontal scrolling within the toc.
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
    return view.frame.origin.y - self.scrollView.contentOffset.y - TOC_SECTION_MARGIN /*- [self getSelectionLine]*/;
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
    // Make it so the last TOCSectionCellView can't scroll off top of screen.
    // Assumes a TOCSectionCellView cells come at end.
    UIView *lastView = self.scrollContainer.subviews.lastObject;

    // Don't report scrolling when changing inset.
    self.scrollView.delegate = nil;
    CGFloat insetAmount = self.scrollView.bounds.size.height - lastView.bounds.size.height - (TOC_SECTION_MARGIN * 2.0f);

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

//TODO: possibly have these constraints, but also a set which positions cells offscreen, that way
// they can be animated between?

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
        constrain(cell, NSLayoutAttributeRight, self.scrollContainer, NSLayoutAttributeRight, (1.0f / [UIScreen mainScreen].scale));
        if (self.sectionCells.firstObject == cell) {
            constrain(cell, NSLayoutAttributeTop, self.scrollContainer, NSLayoutAttributeTop, TOC_SECTION_MARGIN);
        }
        if (self.sectionCells.lastObject == cell) {
            constrain(cell, NSLayoutAttributeBottom, self.scrollContainer, NSLayoutAttributeBottom, -TOC_SECTION_MARGIN);
        }
        if (prevCell) {
            constrain(cell, NSLayoutAttributeTop, prevCell, NSLayoutAttributeBottom, TOC_SECTION_MARGIN);
        }
        prevCell = cell;
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
