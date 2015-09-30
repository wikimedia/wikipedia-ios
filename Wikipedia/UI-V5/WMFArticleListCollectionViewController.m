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

#import "WMFArticleViewController.h"

#import <SSDataSources/SSDataSources.h>
#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>
#import <Masonry/Masonry.h>

#import "WMFArticlePreviewCell.h"

#import "WMFArticleContainerViewController.h"


@interface WMFArticleListCollectionViewController ()
<UICollectionViewDelegate>
@property (strong, nonatomic) MWKArticle* selectedArticle;
@property (nonatomic, strong) IBOutlet UICollectionView* collectionView;
@property (nonatomic, strong) IBOutlet UICollectionViewLayout* collectionViewLayout;

+ (Class)collectionViewClass;

@end

@implementation WMFArticleListCollectionViewController
@synthesize listTransition = _listTransition;

+ (SelfSizingWaterfallCollectionViewLayout*)createLayout {
    return [SelfSizingWaterfallCollectionViewLayout new];
}

+ (Class)collectionViewClass {
    return [UICollectionView class];
}

+ (UICollectionView*)createCollectionView {
    return [[[self collectionViewClass] alloc] initWithFrame:CGRectZero collectionViewLayout:[self createLayout]];
}

#pragma mark - Accessors

- (id<WMFArticleListDynamicDataSource>)dynamicDataSource {
    if ([self.dataSource conformsToProtocol:@protocol(WMFArticleListDynamicDataSource)]) {
        return (id<WMFArticleListDynamicDataSource>)self.dataSource;
    }
    return nil;
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
    self.collectionView.dataSource = nil;

    _dataSource = dataSource;

    [_dataSource setSavedPageList:self.savedPages];

    //HACK: Need to check the window to see if we are on screen. http://stackoverflow.com/a/2777460/48311
    //isViewLoaded is not enough.
    if ([self isViewLoaded] && self.view.window) {
        if (_dataSource) {
            [self connectCollectionViewAndDataSource];
            [[self dynamicDataSource] startUpdating];
        } else {
            [self.collectionView reloadData];
        }
        [self.collectionView wmf_scrollToTop:NO];
    }

    self.title = [_dataSource displayTitle];
}

- (void)setSavedPages:(MWKSavedPageList* __nonnull)savedPages {
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

#pragma mark - DataSource and Collection View Wiring

- (void)connectCollectionViewAndDataSource {
    _dataSource.collectionView = self.collectionView;
    if ([_dataSource respondsToSelector:@selector(estimatedItemHeight)]) {
        [self flowLayout].estimatedItemHeight = _dataSource.estimatedItemHeight;
    }
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

- (void)loadView {
    [super loadView];
    /*
       Support programmatic or Storyboard instantiation by only instantiating views if they weren't set in the storyboard
     */
    if (!self.collectionView) {
        self.collectionView          = [[self class] createCollectionView];
        self.collectionView.delegate = self;
        [self.view addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.trailing.top.and.bottom.equalTo(self.view);
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self connectCollectionViewAndDataSource];

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.collectionView.backgroundColor       = [UIColor clearColor];

    [self flowLayout].numberOfColumns    = 1;
    [self flowLayout].sectionInset       = UIEdgeInsetsMake(10.0, 8.0, 10.0, 8.0);
    [self flowLayout].minimumLineSpacing = 10.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    [self connectCollectionViewAndDataSource];
    [[self dynamicDataSource] startUpdating];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self dynamicDataSource] stopUpdating];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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

@interface WMFIntrinsicSizeCollectionView : UICollectionView

@end

@implementation WMFIntrinsicSizeCollectionView

- (void)setContentSize:(CGSize)contentSize {
    BOOL didChange = CGSizeEqualToSize(self.contentSize, contentSize);
    [super setContentSize:contentSize];
    if (didChange) {
        [self invalidateIntrinsicContentSize];
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    CGSize oldSize = self.contentSize;
    [super layoutSubviews];
    if (!CGSizeEqualToSize(oldSize, self.contentSize)) {
        [self invalidateIntrinsicContentSize];
        [self setNeedsLayout];
    }
}

- (CGSize)intrinsicContentSize {
    return self.contentSize;
}

@end

@implementation WMFSelfSizingArticleListCollectionViewController

+ (Class)collectionViewClass {
    return [WMFIntrinsicSizeCollectionView class];
}

@end
