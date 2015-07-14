
#import "WMFArticleListCollectionViewController.h"
#import "UICollectionView+WMFExtensions.h"
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"

#import "TGLStackedLayout.h"
#import "WMFOffScreenFlowLayout.h"

#import "WMFArticleListTranstion.h"

#import "UIViewController+WMFStoryboardUtilities.h"

NSArray* indexPathsWithIndexSet(NSIndexSet* indexes, NSInteger section) {
    return [indexes bk_mapIndex:^id (NSUInteger index) {
        return [NSIndexPath indexPathForRow:(NSInteger)index inSection:section];
    }];
}

@interface WMFArticleListCollectionViewController ()<TGLStackedLayoutDelegate>

@property (nonatomic, assign, readwrite) WMFArticleListMode mode;

@property (nonatomic, strong) TGLStackedLayout* stackedLayout;
@property (nonatomic, strong) WMFOffScreenFlowLayout* offScreenLayout;

@property (strong, nonatomic) WMFArticleListTranstion* cardTransition;

@end

@implementation WMFArticleListCollectionViewController

- (void)setDataSource:(id<WMFArticleListDataSource> __nullable)dataSource {
    if ([_dataSource isEqual:dataSource]) {
        return;
    }

    [self unobserveDataSource];
    _dataSource = dataSource;
    [self observeDataSource];

    self.title = [_dataSource displayTitle];

    if ([self isViewLoaded]) {
        [self.collectionView setContentOffset:CGPointZero];
        [self.collectionView reloadData];
    }
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
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL* stop) {
        WMFArticleViewControllerContainerCell* cell = (id)[self.collectionView cellForItemAtIndexPath:obj];
        [cell.viewController updateUI];
    }];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor clearColor];

    [self updateListForMode:self.mode animated:NO completion:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateCellSizeBasedOnViewFrame];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// iOS 7 Rotation Support
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self updateCellSizeBasedOnViewFrame];
    }];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS 8+ Rotation Support
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context)
    {
        [self updateCellSizeBasedOnViewFrame];
    }                            completion:NULL];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Update Cell Size

- (void)updateCellSizeBasedOnViewFrame {
    self.stackedLayout.itemSize   = self.view.bounds.size;
    self.offScreenLayout.itemSize = self.view.bounds.size;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataSource articleCount];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WMFArticleViewControllerContainerCell class]) forIndexPath:indexPath];

    if (cell.viewController == nil) {
        WMFArticleViewController* vc = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore savedPages:self.savedPages];
        [vc setMode:WMFArticleControllerModeList animated:NO];
        [cell setViewControllerAndAddViewToContentView:vc];
    }

    [self addChildViewController:cell.viewController];
    cell.viewController.article = [self.dataSource articleForIndexPath:indexPath];

    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController didMoveToParentViewController:self];
}

- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    [[UIApplication sharedApplication] sendAction:@selector(respondsToSelector:) to:nil from:nil forEvent:nil];
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController willMoveToParentViewController:nil];
    [containerCell.viewController removeFromParentViewController];
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = (WMFArticleViewControllerContainerCell*)[collectionView cellForItemAtIndexPath:indexPath];

    WMFArticleViewController* vc = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore savedPages:self.savedPages];
    vc.article = cell.viewController.article;

    self.cardTransition                             = [[WMFArticleListTranstion alloc] initWithPresentingViewController:self presentedViewController:vc contentScrollView:vc.tableView];
    self.cardTransition.nonInteractiveDuration      = 0.5;
    self.cardTransition.presentCardOffset           = vc.tableView.contentInset.top;
    self.cardTransition.offsetOfNextOverlappingCard = self.stackedLayout.topReveal;
    self.cardTransition.movingCardView              = cell;
    vc.transitioningDelegate                        = self.cardTransition;
    vc.modalPresentationStyle                       = UIModalPresentationCustom;

    // if keyboard is visible, dismiss it (e.g. when used to display search results)
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    [self presentViewController:vc animated:YES completion:^{
        [self.recentPages addPageToHistoryWithTitle:cell.viewController.article.title discoveryMethod:[self.dataSource discoveryMethod]];
        [self.recentPages save];
    }];
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
        [self unobserveDataSource];
        [self.dataSource deleteArticleAtIndexPath:indexPath];
        [self observeDataSource];
    }
}

#pragma mark - DataSource KVO

- (void)observeDataSource {
    [self.KVOController observe:_dataSource keyPath:WMF_SAFE_KEYPATH(_dataSource, articles) options:0 block:^(id observer, id object, NSDictionary* change) {
        NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSArray* indexPaths = indexPathsWithIndexSet(change[NSKeyValueChangeIndexesKey], 0);
        [self updateCellsAtIndexPaths:indexPaths change:changeKind];
    }];
}

- (void)unobserveDataSource {
    [self.KVOController unobserve:_dataSource];
}

#pragma mark - Process DataSource Changes

- (void)updateCellsAtIndexPaths:(NSArray*)indexPaths change:(NSKeyValueChange)change {
    [self.collectionView performBatchUpdates:^{
        switch (change) {
            case NSKeyValueChangeInsertion:
                [self insertCellsAtIndexPaths:indexPaths];
                break;
            case NSKeyValueChangeRemoval:
                [self deleteCellsAtIndexPaths:indexPaths];
                break;
            case NSKeyValueChangeReplacement:
                [self reloadCellsAtIndexPaths:indexPaths];
                break;
            case NSKeyValueChangeSetting:
                [self.collectionView reloadData];
                break;
            default:
                break;
        }
    } completion:NULL];
}

- (void)insertCellsAtIndexPaths:(NSArray*)indexPaths {
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)deleteCellsAtIndexPaths:(NSArray*)indexPaths {
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)reloadCellsAtIndexPaths:(NSArray*)indexPaths {
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

@end
