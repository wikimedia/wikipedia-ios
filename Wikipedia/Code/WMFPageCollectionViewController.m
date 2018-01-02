#import "WMFPageCollectionViewController.h"
#import "UICollectionViewLayout+AttributeUtils.h"
@import WMF.WMFDeprecationMacros;

@interface WMFPageCollectionViewController ()

/// Set the current page without triggering any UI updates.
- (void)primitiveSetCurrentPage:(NSUInteger)page;

@end

@implementation WMFPageCollectionViewController

- (void)applyCurrentPage:(BOOL)animated {
    NSParameterAssert(self.isViewLoaded);
    // check page bounds here in case it was set before view was loaded
    NSParameterAssert(self.currentPage < [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0]);

    // can't use scrollToItem because it doesn't handle post-rotation scrolling well on iOS 6
    WMF_TECH_DEBT_TODO(try using scrollToItem
                       : animated:)
    UICollectionViewLayoutAttributes *currentPageAttributes =
        [self.collectionViewLayout layoutAttributesForItemAtIndexPath:
                                       [NSIndexPath indexPathForItem:self.currentPage
                                                           inSection:0]];
    NSAssert(currentPageAttributes,
             @"Layout attributes for current page were nil because %@ was called too early!",
             NSStringFromSelector(_cmd));
    [self.collectionView setContentOffset:currentPageAttributes.frame.origin animated:animated];
}

- (void)setCurrentPage:(NSUInteger)currentPage {
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated {
    [self setCurrentPage:currentPage animated:animated forceViewUpdate:NO];
}

- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated forceViewUpdate:(BOOL)force {
    if (!force && currentPage == _currentPage) {
        return;
    }
    [self primitiveSetCurrentPage:currentPage];
    if (self.isViewLoaded) {
        [self applyCurrentPage:animated];
    }
}

- (void)primitiveSetCurrentPage:(NSUInteger)page {
    // assert that page is within bounds for our collection view's data source, or that the view isn't loaded yet
    NSParameterAssert(![self isViewLoaded] ||
                      page < [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0]);
    _currentPage = page;
}

- (NSUInteger)mostVisibleItemIndex {
    return [self.collectionViewLayout wmf_indexPathHorizontallyClosestToContentOffset].item;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.pagingEnabled = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSUInteger const currentImageIndex = [self mostVisibleItemIndex];
    [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setCurrentPage:currentImageIndex animated:NO forceViewUpdate:YES];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    /*
       only apply visible image index once the collection view has been populated with cells, otherwise calls to get
       layout attributes of the item at `currentPageIndex` will return `nil` (on iOS 6, at least)
     */
    if (!self.didApplyCurrentPage && self.collectionView.visibleCells.count) {
        [self applyCurrentPage:NO];
        /*
           only set the flag *after* the visible index has been updated, to make sure UICollectionViewDelegate callbacks
           don't override it
         */
        self.didApplyCurrentPage = YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self primitiveSetCurrentPage:[self mostVisibleItemIndex]];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self primitiveSetCurrentPage:[self mostVisibleItemIndex]];
}

@end
