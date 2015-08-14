#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleListCollectionViewController_Transitioning.h"
#import "UICollectionView+WMFExtensions.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"

#import "UICollectionView+WMFExtensions.h"
#import "TGLStackedLayout.h"
#import "WMFOffScreenFlowLayout.h"
#import "UIView+WMFDefaultNib.h"
#import "UICollectionView+WMFKVOUpdatableList.h"

#import "WMFArticleContainerViewController.h"

#import "UIViewController+WMFStoryboardUtilities.h"
#import "MediaWikiKit.h"
#import <SSDataSources/SSDataSources.h>

@interface WMFArticleListCollectionViewController ()<TGLStackedLayoutDelegate>

@property (nonatomic, assign, readwrite) WMFArticleListMode mode;

@property (nonatomic, strong) TGLStackedLayout* stackedLayout;
@property (nonatomic, strong) WMFOffScreenFlowLayout* offScreenLayout;

@property (strong, nonatomic) MWKArticle* selectedArticle;

@end

@implementation WMFArticleListCollectionViewController
@synthesize listTransition = _listTransition;

- (void)dealloc {
    _dataSource.collectionView     = nil;
    _dataSource.cellClass          = nil;
    _dataSource.cellConfigureBlock = NULL;
}

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

    _dataSource.collectionView     = nil;
    _dataSource.cellClass          = nil;
    _dataSource.cellConfigureBlock = NULL;

    _dataSource = dataSource;

    _dataSource.cellClass = [WMFArticleViewControllerContainerCell class];

    @weakify(self);
    _dataSource.cellConfigureBlock = ^(WMFArticleViewControllerContainerCell* cell,
                                       MWKArticle* article,
                                       UICollectionView* collectionView,
                                       NSIndexPath* indexPath) {
        @strongify(self);
        if (cell.viewController == nil) {
            WMFArticleViewController* vc =
                [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore
                                                                  savedPages:self.savedPages];
            [vc setMode:WMFArticleControllerModeList animated:NO];
            [cell setViewControllerAndAddViewToContentView:vc];
        }

        [self addChildViewController:cell.viewController];
        cell.viewController.article = [self.dataSource articleForIndexPath:indexPath];
    };

    _dataSource.collectionView = self.collectionView;

    self.title = [_dataSource displayTitle];
}

#pragma mark - List Mode

- (void)setListMode:(WMFArticleListMode)mode animated:(BOOL)animated completion:(nullable dispatch_block_t)completion {
    if (_mode == mode) {
        return;
    }

    _mode = mode;

    if ([self isViewLoaded]) {
        [self updateListForMode:_mode animated:animated completion:completion];
    }
}

- (void)updateListForMode:(WMFArticleListMode)mode animated:(BOOL)animated completion:(nullable dispatch_block_t)completion {
    UICollectionViewLayout* layout;

    switch (mode) {
        case WMFArticleListModeOffScreen: {
            self.offScreenLayout.itemSize = self.view.bounds.size;
            layout                        = self.offScreenLayout;
        }
        break;
        case WMFArticleListModeNormal:
        default: {
            self.stackedLayout.itemSize = self.view.bounds.size;
            layout                      = self.stackedLayout;
        }
        break;
    }

    [self.collectionView wmf_setCollectionViewLayout:layout animated:animated alwaysFireCompletion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Accessors

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self, [self.dataSource class]];
}

- (TGLStackedLayout*)stackedLayout {
    if (!_stackedLayout) {
        TGLStackedLayout* layout = [[TGLStackedLayout alloc] init];
        layout.fillHeight   = YES;
        layout.alwaysBounce = YES;
        layout.delegate     = self;
        layout.itemSize     = self.view.bounds.size;
        _stackedLayout      = layout;
    }

    return _stackedLayout;
}

- (WMFOffScreenFlowLayout*)offScreenLayout {
    if (!_offScreenLayout) {
        WMFOffScreenFlowLayout* layout = [[WMFOffScreenFlowLayout alloc] init];
        layout.itemSize  = self.view.bounds.size;
        _offScreenLayout = layout;
    }

    return _offScreenLayout;
}

- (void)refreshVisibleCells {
    [self.collectionView wmf_enumerateVisibleCellsUsingBlock:
     ^(WMFArticleViewControllerContainerCell* cell, NSIndexPath* path, BOOL* _) {
        [cell.viewController updateUI];
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

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.collectionView.backgroundColor       = [UIColor clearColor];

    [self updateListForMode:self.mode animated:NO completion:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateCellSizeBasedOnViewFrame];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self updateCellSizeBasedOnViewFrame];
    } completion:NULL];
}

#pragma mark - Update Cell Size

- (void)updateCellSizeBasedOnViewFrame {
    self.stackedLayout.itemSize   = self.view.bounds.size;
    self.offScreenLayout.itemSize = self.view.bounds.size;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView
       willDisplayCell:(UICollectionViewCell*)cell
    forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController didMoveToParentViewController:self];
}

- (void)  collectionView:(UICollectionView*)collectionView
    didEndDisplayingCell:(UICollectionViewCell*)cell
      forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController willMoveToParentViewController:nil];
    [containerCell.viewController removeFromParentViewController];
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = (WMFArticleViewControllerContainerCell*)[collectionView cellForItemAtIndexPath:indexPath];
    self.selectedArticle = cell.viewController.article;

    WMFArticleContainerViewController* container = [WMFArticleContainerViewController articleContainerViewControllerWithDataStore:self.dataStore savedPages:self.savedPages];
    container.article = self.selectedArticle;

    [self wmf_hideKeyboard];

    [self.navigationController pushViewController:container animated:YES];

    [self.recentPages addPageToHistoryWithTitle:cell.viewController.article.title
                                discoveryMethod:[self.dataSource discoveryMethod]];
    [self.recentPages save];
}

#pragma mark - TGLStackedLayoutDelegate

- (BOOL)stackLayout:(TGLStackedLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)stackLayout:(TGLStackedLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.dataSource canDeleteItemAtIndexpath:indexPath];
}

- (void)stackLayout:(TGLStackedLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath {
    if ([self.dataSource respondsToSelector:@selector(deleteArticleAtIndexPath:)]) {
        [self.dataSource removeItemAtIndex:indexPath.item];
    }
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
