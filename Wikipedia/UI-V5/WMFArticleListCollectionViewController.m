#import "WMFArticleListCollectionViewController.h"

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
#import "WMFEditingCollectionViewLayout.h"
#import <Masonry/Masonry.h>

#import "WMFArticlePreviewCell.h"

#import "WMFArticleContainerViewController.h"
#import "UIViewController+WMFSearchButton.h"
#import "UIViewController+WMFArticlePresentation.h"

#import "UIColor+WMFHexColor.h"
#import <BlocksKit/BlocksKit.h>

@interface WMFArticleListCollectionViewController ()
<UICollectionViewDelegate,
 WMFSearchPresentationDelegate,
 WMFEditingCollectionViewLayoutDelegate,
 UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) IBOutlet UICollectionView* collectionView;

+ (Class)collectionViewClass;

@end

@implementation WMFArticleListCollectionViewController

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];
}

#pragma mark - Accessors

+ (Class)collectionViewClass {
    return [UICollectionView class];
}

+ (UICollectionView*)createCollectionView {
    return [[[self collectionViewClass] alloc] initWithFrame:CGRectZero collectionViewLayout:[SelfSizingWaterfallCollectionViewLayout new]];
}

- (id<WMFArticleListDynamicDataSource>)dynamicDataSource {
    if ([self.dataSource conformsToProtocol:@protocol(WMFArticleListDynamicDataSource)]) {
        return (id<WMFArticleListDynamicDataSource>)self.dataSource;
    }
    return nil;
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

- (WMFEditingCollectionViewLayout*)editingLayout {
    id layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[WMFEditingCollectionViewLayout class]]) {
        return layout;
    }
    return nil;
}

- (SelfSizingWaterfallCollectionViewLayout*)flowLayout {
    id layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[SelfSizingWaterfallCollectionViewLayout class]]) {
        return layout;
    }
    return nil;
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ dataSourceClass: %@", self, [self.dataSource class]];
}

#pragma mark - Stay Fresh... yo

- (void)observeArticleUpdates {
    [self unobserveArticleUpdates];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    [self refreshAnyVisibleCellsWhichAreShowingTitle:article.title];
}

- (void)refreshAnyVisibleCellsWhichAreShowingTitle:(MWKTitle*)title {
    NSArray* indexPathsToRefresh = [[self.collectionView indexPathsForVisibleItems] bk_select:^BOOL (NSIndexPath* indexPath) {
        MWKArticle* article = [self.dataSource articleForIndexPath:indexPath];
        return [article.title isEqualToTitle:title];
    }];
    [self.collectionView reloadItemsAtIndexPaths:indexPathsToRefresh];
}

- (void)dealloc {
    [self unobserveArticleUpdates];
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

- (void)setupEditingLayout {
    WMFEditingCollectionViewLayout* layout = [[WMFEditingCollectionViewLayout alloc] init];
    layout.editingDelegate                   = self;
    self.collectionView.collectionViewLayout = layout;
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

    [self setupEditingLayout];
    [self connectCollectionViewAndDataSource];

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.collectionView.backgroundColor       = [UIColor wmf_colorWithHex:0xEAECF0 alpha:1.0];

    [self flowLayout].numberOfColumns    = 1;
    [self flowLayout].sectionInset       = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    [self flowLayout].minimumLineSpacing = 1.0;

    [self observeArticleUpdates];

    [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
    } completion:NULL];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [self wmf_hideKeyboard];
    MWKArticle* article = [self.dataSource articleForIndexPath:indexPath];
    if (self.delegate) {
        [self.delegate didSelectTitle:article.title
                               sender:self
                      discoveryMethod:self.dataSource.discoveryMethod];
        return;
    }
    [self wmf_pushArticleViewControllerWithTitle:article.title
                                 discoveryMethod:[self.dataSource discoveryMethod]
                                       dataStore:self.dataStore];
}

- (BOOL)editingLayout:(WMFEditingCollectionViewLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)editingLayout:(WMFEditingCollectionViewLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.dataSource canDeleteItemAtIndexpath:indexPath];
}

- (void)editingLayout:(WMFEditingCollectionViewLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath {
    if ([self.dataSource respondsToSelector:@selector(deleteArticleAtIndexPath:)]) {
        [self.dataSource deleteArticleAtIndexPath:indexPath];
    }
}

#pragma mark - WMFSearchPresentationDelegate

- (MWKDataStore*)searchDataStore {
    return self.dataStore;
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:title
                                     discoveryMethod:discoveryMethod
                                           dataStore:self.dataStore];
    }];
}

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewController:articleViewController];
    }];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    NSIndexPath* previewIndexPath = [(UICollectionView*)previewingContext.sourceView indexPathForItemAtPoint:location];
    if (!previewIndexPath) {
        return nil;
    }
    MWKTitle* title = [[self.dataSource articleForIndexPath:previewIndexPath] title];
    return [[WMFArticleContainerViewController alloc] initWithArticleTitle:title
                                                                 dataStore:[self dataStore]
                                                           discoveryMethod:self.dataSource.discoveryMethod];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(WMFArticleContainerViewController*)viewControllerToCommit {
    if (self.delegate) {
        [self.delegate didCommitToPreviewedArticleViewController:viewControllerToCommit sender:self];
    } else {
        [self wmf_pushArticleViewController:viewControllerToCommit];
    }
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
