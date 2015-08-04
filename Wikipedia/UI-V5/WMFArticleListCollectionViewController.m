#import "WMFArticleListCollectionViewController.h"
#import "UICollectionView+WMFExtensions.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"

#import "UICollectionView+WMFExtensions.h"
#import "TGLStackedLayout.h"
#import "WMFOffScreenFlowLayout.h"
#import "UIView+WMFDefaultNib.h"
#import "UICollectionView+WMFKVOUpdatableList.h"

#import "WMFArticleListTranstion.h"

#import "UIViewController+WMFStoryboardUtilities.h"
#import "MediaWikiKit.h"

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

    self.title = [_dataSource displayTitle];

    if ([self isViewLoaded]) {
        [self.collectionView setContentOffset:CGPointZero];
        [self.collectionView reloadData];
        /*
           can't let KVO callbacks fire until the view is completely reloaded. this prevents crashes when updates occur
           before reloading, which the collectionView assumes are balanced (i.e. we explicitly removed any sections that
           no longer exist)
         */
        [self observeDataSource];
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

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor clearColor];

    [self updateListForMode:self.mode animated:NO completion:NULL];

    [self observeDataSource];
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

// iOS 7 Rotation Support
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self updateCellSizeBasedOnViewFrame];
    }];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS 8+ Rotation Support
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self updateCellSizeBasedOnViewFrame];
    } completion:NULL];

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

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticleViewControllerContainerCell wmf_nibName]
                                                  forIndexPath:indexPath];

    if (cell.viewController == nil) {
        WMFArticleViewController* vc =
            [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore
                                                              savedPages:self.savedPages];
        [vc setMode:WMFArticleControllerModeList animated:NO];
        [cell setViewControllerAndAddViewToContentView:vc];
    }

    [self addChildViewController:cell.viewController];
    cell.viewController.article = [self.dataSource articleForIndexPath:indexPath];

    return cell;
}

#pragma mark - <UICollectionViewDelegate>

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
    WMFArticleViewControllerContainerCell* cell =
        (WMFArticleViewControllerContainerCell*)[collectionView cellForItemAtIndexPath:indexPath];

    WMFArticleViewController* vc = [WMFArticleViewController articleViewControllerWithDataStore:self.dataStore
                                                                                     savedPages:self.savedPages];
    vc.article = cell.viewController.article;

    self.cardTransition =
        [[WMFArticleListTranstion alloc] initWithPresentingViewController:self
                                                  presentedViewController:vc
                                                        contentScrollView:vc.tableView];

    self.cardTransition.nonInteractiveDuration      = 0.5;
    self.cardTransition.presentCardOffset           = vc.tableView.contentInset.top;
    self.cardTransition.offsetOfNextOverlappingCard = self.stackedLayout.topReveal;
    self.cardTransition.movingCardView              = cell;
    vc.transitioningDelegate                        = self.cardTransition;
    vc.modalPresentationStyle                       = UIModalPresentationCustom;

    [self wmf_hideKeyboard];

    [self presentViewController:vc animated:YES completion:^{
        [self.recentPages addPageToHistoryWithTitle:cell.viewController.article.title
                                    discoveryMethod:[self.dataSource discoveryMethod]];
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
    if (![self isViewLoaded] || !self.dataSource) {
        return;
    }
    [self.KVOControllerNonRetaining observe:self.dataSource
                                    keyPath:WMF_SAFE_KEYPATH(self.dataSource, articles)
                                    options:0
                                      block:^(WMFArticleListCollectionViewController* observer,
                                              id object,
                                              NSDictionary* change) {
        [observer.collectionView wmf_updateIndexes:change[NSKeyValueChangeIndexesKey]
                                         inSection:0
                                     forChangeKind:[change[NSKeyValueChangeKindKey] unsignedIntegerValue]];
    }];
}

- (void)unobserveDataSource {
    [self.KVOControllerNonRetaining unobserve:self.dataSource];
}

@end
