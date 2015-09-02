#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"

#import "UICollectionView+WMFExtensions.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIView+WMFDefaultNib.h"
#import "UICollectionView+WMFKVOUpdatableList.h"
#import "UIScrollView+WMFContentOffsetUtils.h"

#import "WMFArticleContainerViewController.h"

#import "UIViewController+WMFStoryboardUtilities.h"

#import "MediaWikiKit.h"
#import <SSDataSources/SSDataSources.h>

#import "WMFArticleViewController.h"

#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

#import "WMFArticlePreviewCell.h"

#import "WMFArticleContainerViewController.h"


@interface WMFArticleListCollectionViewController ()

@property (strong, nonatomic) MWKArticle* selectedArticle;

@end

@implementation WMFArticleListCollectionViewController
@synthesize listTransition = _listTransition;

#pragma mark - Accessors

- (WMFArticleListTransition*)listTransition {
    if (!_listTransition) {
        _listTransition = [[WMFArticleListTransition alloc] initWithListCollectionViewController:self];
    }
    return _listTransition;
}

- (void)setDataSource:(SSArrayDataSource<WMFArticleListDataSource>* __nullable)dataSource {
    if ([_dataSource isEqual:dataSource]) {
        return;
    }

    _dataSource.collectionView = nil;

    _dataSource = dataSource;

    [_dataSource setSavedPageList:self.savedPages];

    if ([self isViewLoaded]) {
        _dataSource.collectionView = self.collectionView;
        [self.collectionView wmf_scrollToTop:NO];
    }

    self.title = [_dataSource displayTitle];
}

- (void)setSavedPages:(MWKSavedPageList * __nonnull)savedPages {
    _savedPages = savedPages;
    [_dataSource setSavedPageList:savedPages];
}

- (SelfSizingWaterfallCollectionViewLayout*)flowLayout {
    return (id)self.collectionView.collectionViewLayout;
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self, [self.dataSource class]];
}

- (void)refreshVisibleCells {
    [self.collectionView wmf_enumerateVisibleCellsUsingBlock:
     ^(WMFArticlePreviewCell* cell, NSIndexPath* path, BOOL* _) {
    }];
}

#pragma mark - Scrolling

- (void)scrollToArticle:(MWKArticle*)article animated:(BOOL)animated {
    NSIndexPath* indexPath = [self.dataSource indexPathForArticle:article];
    if (!indexPath) {
        return;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

- (void)scrollToArticleIfOffscreen:(MWKArticle*)article animated:(BOOL)animated {
    NSIndexPath* indexPath = [self.dataSource indexPathForArticle:article];
    if (!indexPath) {
        return;
    }
    if ([self.collectionView cellForItemAtIndexPath:indexPath]) {
        return;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.dataSource = self.dataSource;

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.collectionView.backgroundColor       = [UIColor clearColor];

    [self flowLayout].estimatedItemHeight = 200;
    [self flowLayout].numberOfColumns     = 1;
    [self flowLayout].sectionInset        = UIEdgeInsetsMake(10.0, 8.0, 10.0, 8.0);
    [self flowLayout].minimumLineSpacing  = 10.0;

    self.dataSource.collectionView = self.collectionView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
    } completion:NULL];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    self.selectedArticle = [self.dataSource articleForIndexPath:indexPath];

    WMFArticleContainerViewController* container = [WMFArticleContainerViewController articleContainerViewControllerWithDataStore:self.dataStore savedPages:self.savedPages];
    container.article = self.selectedArticle;

    [self wmf_hideKeyboard];

    [self.navigationController pushViewController:container animated:YES];

    [self.recentPages addPageToHistoryWithTitle:self.selectedArticle.title
                                discoveryMethod:[self.dataSource discoveryMethod]];
    [self.recentPages save];
}

#pragma mark - WMFArticleListTransitioning

- (UIView*)viewForTransition:(WMFArticleListTransition*)transition {
    NSIndexPath* indexPath = [self.dataSource indexPathForArticle:self.selectedArticle];
    if (!indexPath) {
        return nil;
    }
    return [self.collectionView cellForItemAtIndexPath:indexPath];
}

- (CGRect)frameOfOverlappingListItemsForTransition:(WMFArticleListTransition*)transition {
    NSIndexPath* indexPath     = [self.dataSource indexPathForArticle:self.selectedArticle];
    NSIndexPath* next          = [self.collectionView wmf_indexPathAfterIndexPath:indexPath];
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:next];
    CGRect frame               = cell.frame;
    frame.size.height = CGRectGetHeight(self.collectionView.frame) - frame.origin.y;
    return frame;
}

@end
