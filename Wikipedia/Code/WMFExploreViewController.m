#import "WMFExploreViewController.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "WMFAnnouncement.h"
#import "WMFColumnarCollectionViewLayout.h"
#import "UIFont+WMFStyle.h"
#import "UIViewController+WMFEmptyView.h"
#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"

#import "WMFPicOfTheDayCollectionViewCell.h"
#import "WMFNearbyArticleCollectionViewCell.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFArticleViewController.h"
#import "WMFImageGalleryViewController.h"
#import "WMFRandomArticleViewController.h"
#import "WMFFirstRandomViewController.h"
#import "WMFAnnouncement.h"
#import "WMFChange.h"
#import "WMFCVLAttributes.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "WMFFeedOnThisDayEvent.h"
#import "WMFContentGroup+DetailViewControllers.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFFeedEmptyHeaderFooterReuseIdentifier = @"WMFFeedEmptyHeaderFooterReuseIdentifier";
const NSInteger WMFExploreFeedMaximumNumberOfDays = 30;

@interface WMFExploreViewController () <WMFLocationManagerDelegate, NSFetchedResultsControllerDelegate, WMFColumnarCollectionViewLayoutDelegate, WMFArticlePreviewingActionsDelegate, UIViewControllerPreviewingDelegate, WMFAnnouncementCollectionViewCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching, WMFSideScrollingCollectionViewCellDelegate, UIPopoverPresentationControllerDelegate, UISearchBarDelegate, WMFSaveButtonsControllerDelegate, WMFReadingListActionSheetControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) WMFColumnarCollectionViewLayout *collectionViewLayout;

@property (nonatomic, strong) UIButton *longTitleButton;
@property (nonatomic, strong) UIButton *shortTitleButton;
@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) WMFLocationManager *locationManager;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong, nullable) WMFContentGroup *groupForPreviewedCell;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong, nullable) AFNetworkReachabilityManager *reachabilityManager;

@property (nonatomic, strong) NSMutableArray<WMFSectionChange *> *sectionChanges;
@property (nonatomic, strong) NSMutableArray<WMFObjectChange *> *objectChanges;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *sectionCounts;

@property (nonatomic, strong) NSMutableDictionary<NSString *, WMFExploreCollectionViewCell *> *placeholderCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, WMFExploreCollectionReusableView *> *placeholderViews;

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSURL *> *prefetchURLsByIndexPath;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cachedHeights;
@property (nonatomic, strong) WMFSaveButtonsController *saveButtonsController;
@property (nonatomic, strong) WMFReadingListHintController *readingListHintController;
@property (nonatomic, strong) WMFReadingListActionSheetController *readingListActionSheetController;

@property (nonatomic, getter=isLoadingOlderContent) BOOL loadingOlderContent;
@property (nonatomic, getter=isLoadingNewContent) BOOL loadingNewContent;

@end

@implementation WMFExploreViewController

- (void)setUserStore:(MWKDataStore *)userStore {
    if (_userStore == userStore) {
        return;
    }
    _userStore = userStore;
    self.saveButtonsController = [[WMFSaveButtonsController alloc] initWithDataStore:_userStore];
    self.saveButtonsController.delegate = self;
    self.readingListHintController = [[WMFReadingListHintController alloc] initWithDataStore:self.userStore presenter:self];
    self.readingListActionSheetController = [[WMFReadingListActionSheetController alloc] initWithDataStore:self.userStore presenter:self];
    self.readingListActionSheetController.delegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIButton *)titleButton {
    return (UIButton *)self.navigationItem.titleView;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TODO: delete this init?
    }
    return self;
}

- (void)titleBarButtonPressed {
    [self.collectionView setContentOffset:CGPointMake(0, 0 - self.collectionView.contentInset.top) animated:YES];
}

#pragma mark - Accessors

- (UIRefreshControl *)refreshControl {
    WMFAssertMainThread(@"Refresh control can only be accessed from the main thread");
    [self setupRefreshControl];
    return _refreshControl;
}

- (void)setupRefreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refreshControlActivated) forControlEvents:UIControlEventValueChanged];
        _refreshControl.layer.zPosition = -100;
        if ([self.collectionView respondsToSelector:@selector(setRefreshControl:)]) {
            self.collectionView.refreshControl = _refreshControl;
        } else {
            [self.collectionView addSubview:_refreshControl];
        }
    }
}
- (MWKSavedPageList *)savedPages {
    NSParameterAssert(self.userStore);
    return self.userStore.savedPageList;
}

- (MWKHistoryList *)history {
    NSParameterAssert(self.userStore);
    return self.userStore.historyList;
}

- (WMFLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [WMFLocationManager fineLocationManager];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSURL *)currentSiteURL {
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

- (NSUInteger)numberOfSectionsInExploreFeed {
    return [self.fetchedResultsController.sections.firstObject numberOfObjects];
}

- (BOOL)canScrollToTop {
    WMFContentGroup *group = [self sectionAtIndex:0];
    return group != nil;
}

- (BOOL)isScrolledToTop {
    return self.collectionView.contentOffset.y <= 0 - self.collectionView.contentInset.top;
}

#pragma mark - Section Access

- (nullable WMFContentGroup *)sectionAtIndex:(NSUInteger)sectionIndex {
    id<NSFetchedResultsSectionInfo> section = [[self.fetchedResultsController sections] firstObject];
    if (sectionIndex >= [section numberOfObjects]) {
        return nil;
    }
    return (WMFContentGroup *)[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:sectionIndex inSection:0]];
}

- (nullable WMFContentGroup *)sectionForIndexPath:(NSIndexPath *)indexPath {
    return [self sectionAtIndex:indexPath.section];
}

#pragma mark - Content Access

- (nullable NSURL *)contentURLForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    WMFFeedDisplayType displayType = [section displayTypeForItemAtIndex:indexPath.item];
    id contentPreview = section.contentPreview;
    if (displayType == WMFFeedDisplayTypeRelatedPagesSourceArticle) {
        return section.articleURL;
    } else if (displayType == WMFFeedDisplayTypeRelatedPages) {
        if (![contentPreview isKindOfClass:[NSArray class]]) {
            return nil;
        }
        NSInteger index = indexPath.item - 1;
        if (index >= [contentPreview count]) {
            return nil;
        }
        id preview = contentPreview[index];
        if (![preview isKindOfClass:[NSURL class]]) {
            return nil;
        }
        return preview;
    } else if ([section contentType] == WMFContentTypeTopReadPreview) {
        if (![contentPreview isKindOfClass:[NSArray class]]) {
            return nil;
        }
        if (indexPath.item >= [contentPreview count]) {
            return nil;
        }
        id preview = contentPreview[indexPath.item];
        if (![preview isKindOfClass:[WMFFeedTopReadArticlePreview class]]) {
            return nil;
        }
        return [(WMFFeedTopReadArticlePreview *)preview articleURL];
        
    } else if ([section contentType] == WMFContentTypeURL) {
        if ([contentPreview isKindOfClass:[NSURL class]]) {
            return contentPreview;
        }
        if (![contentPreview isKindOfClass:[NSArray class]]) {
            return nil;
        }
        if (indexPath.item >= [contentPreview count]) {
            return nil;
        }
        id preview = contentPreview[indexPath.item];
        if (![preview isKindOfClass:[NSURL class]]) {
            return nil;
        }
        return preview;
    } else {
        return nil;
    }
}

- (nullable NSURL *)imageURLForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    NSURL *articleURL = nil;
    NSInteger width = 0;
    id contentPreview = section.contentPreview;
    if (![contentPreview isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if (indexPath.item >= [contentPreview count]) {
        return nil;
    }
    id object = contentPreview[indexPath.item];
    if ([section contentType] == WMFContentTypeTopReadPreview && [object isKindOfClass:[WMFFeedTopReadArticlePreview class]]) {
        articleURL = [(WMFFeedTopReadArticlePreview *)object articleURL];
        width = self.traitCollection.wmf_listThumbnailWidth;
    } else if ([section contentType] == WMFContentTypeURL && [object isKindOfClass:[NSURL class]]) {
        articleURL = (NSURL *)object;
        switch (section.contentGroupKind) {
            case WMFContentGroupKindRelatedPages:
            case WMFContentGroupKindPictureOfTheDay:
            case WMFContentGroupKindRandom:
            case WMFContentGroupKindFeaturedArticle:
                width = self.traitCollection.wmf_leadImageWidth;
                break;
            default:
                width = self.traitCollection.wmf_listThumbnailWidth;
                break;
        }
        
    } else if ([section contentType] == WMFContentTypeStory && [object isKindOfClass:[WMFFeedNewsStory class]]) {
        WMFFeedNewsStory *newsStory = (WMFFeedNewsStory *)object;
        articleURL = [[newsStory featuredArticlePreview] articleURL] ?: [[[newsStory articlePreviews] firstObject] articleURL];
        width = self.traitCollection.wmf_nearbyThumbnailWidth;
    } else {
        return nil;
    }
    if (!articleURL || width <= 0) {
        return nil;
    }
    WMFArticle *article = [self.userStore fetchArticleWithURL:articleURL];
    return [article imageURLForWidth:width];
}

- (nullable WMFArticle *)articleForIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self contentURLForIndexPath:indexPath];
    if (url == nil) {
        return nil;
    }
    return [self.userStore fetchArticleWithURL:url];
}

- (nullable WMFFeedTopReadArticlePreview *)topReadPreviewForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    id contentPreview = group.contentPreview;
    if (![contentPreview isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if (indexPath.item >= [contentPreview count]) {
        return nil;
    }
    id preview = [contentPreview objectAtIndex:indexPath.item];
    if (![preview isKindOfClass:[WMFFeedTopReadArticlePreview class]]) {
        return nil;
    }
    return preview;
}

#pragma mark - Refresh Control

- (void)resetRefreshControl {
    if (![self.refreshControl isRefreshing]) {
        return;
    }
    [self.refreshControl endRefreshing];
}

- (void)dismissNotificationCard {
    NSURL *groupURL = [WMFContentGroup notificationContentGroupURL];
    NSManagedObjectContext *moc = self.userStore.viewContext;
    WMFContentGroup *group = [moc contentGroupForURL:groupURL];
    if (group) {
        [moc deleteObject:group];
        NSError *contentGroupSaveError = nil;
        [self.userStore save:&contentGroupSaveError];
        if (contentGroupSaveError) {
            DDLogError(@"Error saving after enabling notifications: %@", contentGroupSaveError);
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    self.collectionViewLayout = [[WMFColumnarCollectionViewLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewLayout];
    [self.view wmf_addSubviewWithConstraintsToEdges:self.collectionView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if ([self.collectionView respondsToSelector:@selector(setPrefetchDataSource:)]) {
        self.collectionView.prefetchDataSource = self;
        self.collectionView.prefetchingEnabled = YES;
    }
    
    self.longTitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.longTitleButton.adjustsImageWhenHighlighted = YES;
    [self.longTitleButton setImage:[UIImage imageNamed:@"wikipedia"] forState:UIControlStateNormal];
    [self.longTitleButton sizeToFit];
    [self.longTitleButton addTarget:self action:@selector(titleBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.shortTitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shortTitleButton.adjustsImageWhenHighlighted = YES;
    [self.shortTitleButton setImage:[UIImage imageNamed:@"W"] forState:UIControlStateNormal];
    [self.shortTitleButton sizeToFit];
    self.shortTitleButton.alpha = 0;
    [self.shortTitleButton addTarget:self action:@selector(titleBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *titleView = [[UIView alloc] initWithFrame:self.longTitleButton.bounds];
    [titleView addSubview:self.longTitleButton];
    [titleView addSubview:self.shortTitleButton];
    self.shortTitleButton.center = titleView.center;
    
    self.navigationItem.titleView = titleView;
    self.navigationItem.isAccessibilityElement = YES;
    self.navigationItem.accessibilityTraits |= UIAccessibilityTraitHeader;
    
    UIView *searchBarContainerView = [[UIView alloc] init];
    NSLayoutConstraint *searchBarHeight = [searchBarContainerView.heightAnchor constraintEqualToConstant:44];
    [searchBarContainerView addConstraint:searchBarHeight];
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = WMFLocalizedStringWithDefaultValue(@"search-field-placeholder-text", nil, nil, @"Search Wikipedia", @"Search field placeholder text");
    
    [searchBarContainerView wmf_addSubview:self.searchBar withConstraintsToEdgesWithInsets:UIEdgeInsetsMake(0, 0, 3, 0) priority:UILayoutPriorityRequired];
    
    [self.navigationBar addExtendedNavigationBarView:searchBarContainerView];
    
    self.sectionChanges = [NSMutableArray arrayWithCapacity:10];
    self.objectChanges = [NSMutableArray arrayWithCapacity:10];
    self.sectionCounts = [NSMutableArray arrayWithCapacity:100];
    self.placeholderCells = [NSMutableDictionary dictionaryWithCapacity:10];
    self.placeholderViews = [NSMutableDictionary dictionaryWithCapacity:10];
    self.prefetchURLsByIndexPath = [NSMutableDictionary dictionaryWithCapacity:10];
    self.cachedHeights = [NSMutableDictionary dictionaryWithCapacity:10];
    
    [self registerCellsAndViews];
    [self setupRefreshControl];
    
    [super viewDidLoad]; // intentionally at the bottom of the method for theme application
}

- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion {
    [self.userStore.feedContentController updateFeedSourcesWithDate:date
                                                      userInitiated:wasUserInitiated
                                                         completion:^{
                                                             WMFAssertMainThread(@"Completion is assumed to be called on the main thread.");
                                                             [self resetRefreshControl];
                                                             
                                                             if (date == nil) { //only hide on a new content update
                                                                 [self startMonitoringReachabilityIfNeeded];
                                                                 [self showOfflineEmptyViewIfNeeded];
                                                             }
                                                             if (completion) {
                                                                 completion();
                                                             }
                                                         }];
}

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nonnull dispatch_block_t)completion {
    if (self.isLoadingNewContent) {
        return;
    }
    self.loadingNewContent = YES;
    if (!self.refreshControl.isRefreshing) {
        [self.refreshControl beginRefreshing];
        if (self.isScrolledToTop && self.numberOfSectionsInExploreFeed == 0) {
            self.collectionView.contentOffset = CGPointMake(0, 0 - self.collectionView.contentInset.top - self.refreshControl.frame.size.height);
        }
    }
    [self updateFeedSourcesWithDate:nil
                      userInitiated:wasUserInitiated
                         completion:^{
                             self.loadingNewContent = NO;
                             completion();
                         }];
}

- (void)refreshControlActivated {
    [self updateFeedSourcesUserInitiated:YES
                              completion:^{
                              }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }
    
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        if ([cell conformsToProtocol:@protocol(WMFSubCellProtocol)]) {
            [(id<WMFSubCellProtocol>)cell deselectSelectedSubItemsAnimated:animated];
        }
    }
    
    if (!self.reachabilityManager) {
        self.reachabilityManager = [AFNetworkReachabilityManager manager];
    }
    
    if (!self.fetchedResultsController) {
        [self.userStore prefetchArticles]; // articles aren't linked to content groups by a core data relationship, they're fetched on demand. it helps to warm up the article cache with one big fetch instead of a lot of individual fetches.
        NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isVisible == %@", @(YES)];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"midnightUTCDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"dailySortPriority" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.userStore.viewContext sectionNameKeyPath:nil cacheName:nil];
        frc.delegate = self;
        [frc performFetch:nil];
        self.fetchedResultsController = frc;
        [self updateSectionCounts];
        [self.collectionView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.userStore);
    [super viewDidAppear:animated];
    
    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_exploreViewActivity]];
    [self startMonitoringReachabilityIfNeeded];
    [self showOfflineEmptyViewIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopMonitoringReachability];
}

- (void)resetLayoutCache {
    [self.cachedHeights removeAllObjects];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [self resetLayoutCache];
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
    UIContentSizeCategory previousContentSizeCategory = previousTraitCollection.preferredContentSizeCategory;
    UIContentSizeCategory contentSizeCategory = self.traitCollection.preferredContentSizeCategory;
    if (contentSizeCategory && ![previousContentSizeCategory isEqualToString:contentSizeCategory]) {
        [self contentSizeCategoryDidChange:nil];
    }
}

- (void)contentSizeCategoryDidChange:(nullable NSNotification *)note {
    [self resetLayoutCache];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [self resetLayoutCache];
    [super didReceiveMemoryWarning];
}

#pragma mark - Offline Handling

- (void)stopMonitoringReachability {
    [self.reachabilityManager setReachabilityStatusChangeBlock:NULL];
    [self.reachabilityManager stopMonitoring];
}

- (void)startMonitoringReachabilityIfNeeded {
    if (self.numberOfSectionsInExploreFeed > 0) {
        [self stopMonitoringReachability];
    } else {
        [self.reachabilityManager startMonitoring];
        @weakify(self);
        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            @strongify(self);
            dispatchOnMainQueue(^{
                switch (status) {
                    case AFNetworkReachabilityStatusReachableViaWWAN:
                    case AFNetworkReachabilityStatusReachableViaWiFi: {
                        [self updateFeedSourcesUserInitiated:NO
                                                  completion:^{
                                                  }];
                    } break;
                    case AFNetworkReachabilityStatusNotReachable: {
                        [self showOfflineEmptyViewIfNeeded];
                    }
                    default:
                        break;
                }
                
            });
        }];
    }
}

- (void)showOfflineEmptyViewIfNeeded {
    if (!self.isViewLoaded || !self.fetchedResultsController) {
        return;
    }
    if (self.numberOfSectionsInExploreFeed > 0) {
        [self wmf_hideEmptyView];
    } else {
        if ([self wmf_isShowingEmptyView]) {
            return;
        }
        
        if (self.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable) {
            return;
        }
        
        [self.refreshControl endRefreshing];
        [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoFeed theme:self.theme frame:self.view.bounds];
    }
}

- (NSInteger)numberOfItemsInContentGroup:(WMFContentGroup *)contentGroup {
    NSParameterAssert(contentGroup);
    id contentPreview = contentGroup.contentPreview;
    if (![contentPreview isKindOfClass:[NSArray class]]) {
        return 1;
    }
    NSInteger countOfFeedContent = [contentPreview count];
    switch (contentGroup.contentGroupKind) {
        case WMFContentGroupKindNews:
            return 1;
        case WMFContentGroupKindOnThisDay:
            return 1;
        case WMFContentGroupKindRelatedPages:
            return MIN(countOfFeedContent, [contentGroup maxNumberOfCells]) + 1;
        default:
            return MIN(countOfFeedContent, [contentGroup maxNumberOfCells]);
    }
}

- (void)updateSectionCounts {
    [self.sectionCounts removeAllObjects];
    NSInteger sectionCount = self.numberOfSectionsInExploreFeed;
    
    for (NSInteger i = 0; i < sectionCount; i++) {
        [self.sectionCounts addObject:@([self numberOfItemsInSection:i])];
    }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    WMFContentGroup *contentGroup = [self sectionAtIndex:section];
    return [self numberOfItemsInContentGroup:contentGroup];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.numberOfSectionsInExploreFeed;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    if (!contentGroup) {
        return [UICollectionViewCell new];
    }
    WMFArticle *article = [self articleForIndexPath:indexPath];
    WMFFeedDisplayType displayType = [contentGroup displayTypeForItemAtIndex:indexPath.item];
    switch (displayType) {
        case WMFFeedDisplayTypeRanked:
        case WMFFeedDisplayTypePage:
        case WMFFeedDisplayTypeContinueReading:
        case WMFFeedDisplayTypeMainPage:
        case WMFFeedDisplayTypeRandom:
        case WMFFeedDisplayTypePageWithPreview:
        case WMFFeedDisplayTypeRelatedPagesSourceArticle:
        case WMFFeedDisplayTypeRelatedPages: {
            NSString *reuseIdentifier = [self reuseIdentifierForCellAtIndexPath:indexPath displayType:displayType];
            WMFArticleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
            [self configureArticleCell:cell withSection:contentGroup displayType:displayType withArticle:article atIndexPath:indexPath layoutOnly:NO];
            return (UICollectionViewCell *)cell;
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            WMFNearbyArticleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureNearbyCell:cell withArticle:article atIndexPath:indexPath];
            return cell;
            
        } break;
        case WMFFeedDisplayTypePhoto: {
            WMFPicOfTheDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            id preview = contentGroup.contentPreview;
            if ([preview isKindOfClass:[WMFFeedImage class]]) {
                [self configurePhotoCell:cell withImageInfo:preview atIndexPath:indexPath];
            }
            return cell;
        } break;
        case WMFFeedDisplayTypeStory: {
            WMFNewsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WMFNewsCollectionViewCell" forIndexPath:indexPath];
            [self configureNewsCell:cell withContentGroup:contentGroup layoutOnly:NO];
            return cell;
        } break;
        case WMFFeedDisplayTypeEvent: {
            WMFOnThisDayExploreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WMFOnThisDayExploreCollectionViewCell" forIndexPath:indexPath];
            [self configureOnThisDayCell:cell withContentGroup:contentGroup layoutOnly:NO];
            return cell;
        } break;
        case WMFFeedDisplayTypeTheme:
        case WMFFeedDisplayTypeNotification:
        case WMFFeedDisplayTypeAnnouncement: {
            WMFAnnouncementCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WMFAnnouncementCollectionViewCell" forIndexPath:indexPath];
            [self configureAnnouncementCell:cell withContentGroup:contentGroup atIndexPath:indexPath];
            return cell;
        }
        default:
            NSAssert(false, @"Unknown Display Type");
            return nil;
            break;
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView viewForSectionHeaderAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView viewForSectionFooterAtIndexPath:indexPath];
    } else {
        NSAssert(false, @"Unknown Supplementary View Type");
        return [UICollectionReusableView new];
    }
}

- (NSString *)reuseIdentifierForCellAtIndexPath:(NSIndexPath *)indexPath displayType:(WMFFeedDisplayType)displayType {
    NSString *reuseIdentifier = @"WMFArticleRightAlignedImageCollectionViewCell";
    switch (displayType) {
        case WMFFeedDisplayTypeRanked:
            reuseIdentifier = @"WMFRankedArticleCollectionViewCell";
            break;
        case WMFFeedDisplayTypeStory:
            reuseIdentifier = @"WMFNewsCollectionViewCell";
            break;
        case WMFFeedDisplayTypeEvent:
            reuseIdentifier = @"WMFOnThisDayExploreCollectionViewCell";
            break;
        case WMFFeedDisplayTypeContinueReading:
        case WMFFeedDisplayTypeRelatedPagesSourceArticle:
        case WMFFeedDisplayTypeRandom:
        case WMFFeedDisplayTypePageWithPreview:
            reuseIdentifier = @"WMFArticleFullWidthImageCollectionViewCell";
        default:
            break;
    }
    return reuseIdentifier;
}

#pragma mark - WMFColumnarCollectionViewLayoutDelgate

- (WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize readableWidth:(CGFloat)readableWidth {
    return [WMFCVLMetrics metricsWithBoundsSize:boundsSize readableWidth:readableWidth layoutDirection:[[UIApplication sharedApplication] userInterfaceLayoutDirection]];
}

- (WMFLayoutEstimate)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    WMFLayoutEstimate estimate;
    WMFFeedDisplayType displayType = [section displayTypeForItemAtIndex:indexPath.item];
    switch (displayType) {
        case WMFFeedDisplayTypeRanked:
        case WMFFeedDisplayTypePage:
        case WMFFeedDisplayTypeStory:
        case WMFFeedDisplayTypeEvent:
        case WMFFeedDisplayTypeContinueReading:
        case WMFFeedDisplayTypeMainPage:
        case WMFFeedDisplayTypePageWithPreview:
        case WMFFeedDisplayTypeRandom:
        case WMFFeedDisplayTypeRelatedPagesSourceArticle:
        case WMFFeedDisplayTypeRelatedPages: {
            WMFArticle *article = [self articleForIndexPath:indexPath];
            NSString *key = (displayType == WMFFeedDisplayTypeStory || displayType == WMFFeedDisplayTypeEvent) ? section.key : article.key;
            
            NSString *reuseIdentifier = [self reuseIdentifierForCellAtIndexPath:indexPath displayType:displayType];
            NSString *cacheKey = [NSString stringWithFormat:@"%@-%lli-%@-%lli", reuseIdentifier, (long long)displayType, key, (long long)columnWidth];
            
            NSNumber *cachedValue = [self.cachedHeights objectForKey:cacheKey];
            if (cachedValue) {
                estimate.height = [cachedValue doubleValue];
                estimate.precalculated = YES;
                break;
            }
            
            switch (displayType) {
                case WMFFeedDisplayTypeStory: {
                    WMFNewsCollectionViewCell *cell = [self placeholderCellForIdentifier:reuseIdentifier];
                    [self configureNewsCell:cell withContentGroup:section layoutOnly:YES];
                    CGSize size = [cell sizeThatFits:CGSizeMake(columnWidth, UIViewNoIntrinsicMetric)];
                    estimate.height = size.height;
                    break;
                }
                case WMFFeedDisplayTypeEvent: {
                    WMFOnThisDayExploreCollectionViewCell *cell = [self placeholderCellForIdentifier:reuseIdentifier];
                    [self configureOnThisDayCell:cell withContentGroup:section layoutOnly:YES];
                    CGSize size = [cell sizeThatFits:CGSizeMake(columnWidth, UIViewNoIntrinsicMetric)];
                    estimate.height = size.height;
                    break;
                }
                default: {
                    WMFArticleCollectionViewCell *cell = [self placeholderCellForIdentifier:reuseIdentifier];
                    [self configureArticleCell:cell withSection:section displayType:displayType withArticle:article atIndexPath:indexPath layoutOnly:YES];
                    CGSize size = [cell sizeThatFits:CGSizeMake(columnWidth, UIViewNoIntrinsicMetric)];
                    estimate.height = size.height;
                    break;
                }
            }
            estimate.precalculated = YES;
            [self.cachedHeights setObject:@(estimate.height) forKey:cacheKey];
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            estimate.height = [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePhoto: {
            estimate.height = [WMFPicOfTheDayCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypeTheme:
        case WMFFeedDisplayTypeNotification:
        case WMFFeedDisplayTypeAnnouncement: {
            WMFAnnouncementCollectionViewCell *cell = [self placeholderCellForIdentifier:@"WMFAnnouncementCollectionViewCell"];
            [self configureAnnouncementCell:cell withContentGroup:section atIndexPath:indexPath];
            CGSize size = [cell sizeThatFits:CGSizeMake(columnWidth, UIViewNoIntrinsicMetric)];
            estimate.height = size.height;
            estimate.precalculated = YES;
        } break;
        default:
            NSAssert(false, @"Unknown display Type");
            estimate.height = 100;
            break;
    }
    return estimate;
}

- (WMFLayoutEstimate)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFLayoutEstimate estimate;
    WMFContentGroup *group = [self sectionAtIndex:section];
    WMFFeedHeaderType headerType = group.headerType;
    switch (headerType) {
        case WMFFeedHeaderTypeNone:
            estimate.height = 0;
            estimate.precalculated = YES;
            break;
        default: {
            NSString *reuseIdentifier = [WMFExploreSectionHeader wmf_nibName];
            NSString *cacheKey = [NSString stringWithFormat:@"%@-%lli-%lli", reuseIdentifier, (long long)headerType, (long long)columnWidth]; //Only need to cache one value - height is isn't different from section to section, only from dynamic type differences
            NSNumber *cachedValue = [self.cachedHeights objectForKey:cacheKey];
            if (cachedValue) {
                estimate.height = [cachedValue doubleValue];
                estimate.precalculated = YES;
                break;
            }
            WMFExploreSectionHeader *header = (WMFExploreSectionHeader *)[self placeholderForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseIdentifier];
            [self configureHeader:header withContentGroup:group forSectionAtIndex:section];
            CGRect frameToFit = CGRectMake(0, 0, columnWidth, UIViewNoIntrinsicMetric);
            WMFCVLAttributes *attributesToFit = [WMFCVLAttributes new];
            attributesToFit.frame = frameToFit;
            WMFCVLAttributes *attributes = (WMFCVLAttributes *)[header preferredLayoutAttributesFittingAttributes:attributesToFit];
            estimate.height = attributes.frame.size.height;
            estimate.precalculated = YES;
            [self.cachedHeights setObject:@(estimate.height) forKey:cacheKey];
        } break;
    }
    return estimate;
}

- (WMFLayoutEstimate)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFLayoutEstimate estimate;
    WMFContentGroup *group = [self sectionAtIndex:section];
    WMFFeedMoreType moreType = group.moreType;
    switch (moreType) {
        case WMFFeedMoreTypeNone:
            estimate.height = 0;
            estimate.precalculated = YES;
            break;
        default: {
            NSString *reuseIdentifier = nil;
            if (group.moreType == WMFFeedMoreTypeLocationAuthorization) {
                reuseIdentifier = [WMFTitledExploreSectionFooter wmf_nibName];
            } else {
                reuseIdentifier = [WMFExploreSectionFooter wmf_nibName];
            }
            NSString *cacheKey = [NSString stringWithFormat:@"%@-%lli-%lli", reuseIdentifier, (long long)moreType, (long long)columnWidth];
            NSNumber *cachedValue = [self.cachedHeights objectForKey:cacheKey];
            if (cachedValue) {
                estimate.height = [cachedValue doubleValue];
                estimate.precalculated = YES;
                break;
            }
            CGRect frameToFit = CGRectMake(0, 0, columnWidth, UIViewNoIntrinsicMetric);
            WMFExploreCollectionReusableView *footer = [self placeholderForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:reuseIdentifier];
            if ([footer isKindOfClass:[WMFTitledExploreSectionFooter class]]) {
                [self configureTitledExploreSectionFooter:(WMFTitledExploreSectionFooter *)footer forSectionAtIndex:section];
            } else {
                [self configureFooter:(WMFExploreSectionFooter *)footer withContentGroup:group];
            }
            WMFCVLAttributes *attributesToFit = [WMFCVLAttributes new];
            attributesToFit.frame = frameToFit;
            WMFCVLAttributes *attributes = (WMFCVLAttributes *)[footer preferredLayoutAttributesFittingAttributes:attributesToFit];
            estimate.height = attributes.frame.size.height;
            estimate.precalculated = YES;
            [self.cachedHeights setObject:@(estimate.height) forKey:cacheKey];
        } break;
    }
    return estimate;
}

- (BOOL)collectionView:(UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index {
    WMFContentGroup *section = [self sectionAtIndex:index];
    return [section prefersWiderColumn];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionImpressionInContext:self contentType:section value:section];
    
    if ([cell isKindOfClass:[WMFArticleCollectionViewCell class]]) {
        WMFSaveButton *saveButton = [(WMFArticleCollectionViewCell *)cell saveButton];
        if (saveButton) {
            WMFArticle *article = [self articleForIndexPath:indexPath];
            [self.saveButtonsController willDisplaySaveButton:saveButton forArticle:article];
        }
    }
    
    if ([cell isKindOfClass:[WMFSideScrollingCollectionViewCell class]]) {
        WMFSideScrollingCollectionViewCell *sideScrollingCell = (WMFSideScrollingCollectionViewCell *)cell;
        sideScrollingCell.selectionDelegate = self;
    }
    
    if ([WMFLocationManager isAuthorized]) {
        if ([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]] || [self isDisplayingLocationCell]) {
            [self.locationManager startMonitoringLocation];
        } else {
            [self.locationManager stopMonitoringLocation];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[WMFArticleCollectionViewCell class]]) {
        WMFSaveButton *saveButton = [(WMFArticleCollectionViewCell *)cell saveButton];
        if (saveButton) {
            WMFArticle *article = [self articleForIndexPath:indexPath];
            [self.saveButtonsController didEndDisplayingSaveButton:saveButton forArticle:article];
        }
    }
    
    if ([cell isKindOfClass:[WMFSideScrollingCollectionViewCell class]]) {
        WMFSideScrollingCollectionViewCell *sideScrollingCell = (WMFSideScrollingCollectionViewCell *)cell;
        sideScrollingCell.selectionDelegate = nil;
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(group);
    if ([group headerType] == WMFFeedHeaderTypeNone) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier forIndexPath:indexPath];
    }
    
    WMFExploreSectionHeader *header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];
    
    [self configureHeader:header withContentGroup:group forSectionAtIndex:indexPath.section];
    
    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        NSIndexPath *indexPathForSection = [self.fetchedResultsController indexPathForObject:group];
        if (!indexPathForSection) {
            return;
        }
        [self didTapHeaderInSection:indexPathForSection.row];
    };
    
    return header;
}

- (void)configureHeader:(WMFExploreSectionHeader *)header withContentGroup:(WMFContentGroup *)group forSectionAtIndex:(NSInteger)index {
    NSParameterAssert([group headerIcon]);
    NSParameterAssert([group headerTitle]);
    NSParameterAssert([group headerSubTitle]);
    header.image = [[group headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.imageTintColor = [group headerIconTintColor];
    header.imageBackgroundColor = [group headerIconBackgroundColor];
    
    header.title = [[group headerTitle] mutableCopy];
    header.subTitle = [[group headerSubTitle] mutableCopy];
    
    if (([group blackListOptions] & WMFFeedBlacklistOptionSection) || (([group blackListOptions] & WMFFeedBlacklistOptionContent) && [group headerContentURL])) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton removeTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        header.rightButton.tag = index;
        [header.rightButton addTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton removeTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [header applyTheme:self.theme];
}

- (void)headerRightButtonPressed:(UIButton *)sender {
    NSInteger sectionIndex = sender.tag;
    WMFContentGroup *section = [self sectionAtIndex:sectionIndex];
    
    UIAlertController *menuActionSheet = [self menuActionSheetForSection:section];
    if (!menuActionSheet) {
        return;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        menuActionSheet.modalPresentationStyle = UIModalPresentationPopover;
        menuActionSheet.popoverPresentationController.sourceView = sender;
        menuActionSheet.popoverPresentationController.sourceRect = [sender bounds];
        menuActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self presentViewController:menuActionSheet animated:YES completion:nil];
    } else {
        menuActionSheet.popoverPresentationController.sourceView = self.navigationController.tabBarController.tabBar.superview;
        menuActionSheet.popoverPresentationController.sourceRect = self.navigationController.tabBarController.tabBar.frame;
        [self presentViewController:menuActionSheet animated:YES completion:nil];
    }
}

#pragma mark - UICollectionViewDataSourcePrefetching

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        if (self.prefetchURLsByIndexPath[indexPath]) {
            continue;
        }
        NSURL *imageURL = [self imageURLForIndexPath:indexPath];
        if (!imageURL) {
            continue;
        }
        self.prefetchURLsByIndexPath[indexPath] = imageURL;
        [[WMFImageController sharedInstance] prefetchWithURL:imageURL
                                                  completion:^{
                                                      [self.prefetchURLsByIndexPath removeObjectForKey:indexPath];
                                                  }];
    }
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        NSURL *imageURL = self.prefetchURLsByIndexPath[indexPath];
        if (!imageURL) {
            continue;
        }
        [self.prefetchURLsByIndexPath removeObjectForKey:indexPath];
    }
}

#pragma mark - WMFHeaderMenuProviding

- (nullable UIAlertController *)menuActionSheetForSection:(WMFContentGroup *)section {
    switch (section.contentGroupKind) {
        case WMFContentGroupKindRelatedPages: {
            NSURL *url = [section headerContentURL];
            UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"home-hide-suggestion-prompt", nil, nil, @"Hide this suggestion", @"Title of button shown for users to confirm the hiding of a suggestion in the explore feed")
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [self.userStore setIsExcludedFromFeed:YES withArticleURL:url];
                                                        [self.userStore.viewContext removeContentGroup:section];
                                                    }]];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"home-hide-suggestion-cancel", nil, nil, @"Cancel", @"Title of the button for cancelling the hiding of an explore feed suggestion\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
            return sheet;
        }
        case WMFContentGroupKindLocationPlaceholder: {
            UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"explore-nearby-placeholder-dismiss", nil, nil, @"Dismiss", @"Action button that will dismiss the nearby placeholder\n{{Identical|Dismiss}}")
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [[NSUserDefaults wmf_userDefaults] wmf_setExploreDidPromptForLocationAuthorization:YES];
                                                        section.wasDismissed = YES;
                                                        [section updateVisibility];
                                                    }]];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"explore-nearby-placeholder-cancel", nil, nil, @"Cancel", @"Action button that will cancel dismissal of the nearby placeholder\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
            return sheet;
        }
        default:
            return nil;
    }
}

- (void)configureTitledExploreSectionFooter:(WMFTitledExploreSectionFooter *)footer forSectionAtIndex:(NSInteger)index {
    footer.titleLabel.text = [EnableLocationViewController localizedEnableLocationExploreTitle];
    footer.descriptionLabel.text = [EnableLocationViewController localizedEnableLocationDescription];
    [footer.enableLocationButton setTitle:[EnableLocationViewController localizedEnableLocationButtonTitle] forState:UIControlStateNormal];
    [footer.enableLocationButton removeTarget:self action:@selector(enableLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside]; // ensures the view controller isn't duplicated in the target list, causing duplicate actions to be sent
    footer.enableLocationButton.tag = index;
    [footer.enableLocationButton addTarget:self action:@selector(enableLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [footer applyTheme:self.theme];
}

- (void)configureFooter:(WMFExploreSectionFooter *)footer withContentGroup:(WMFContentGroup *)group {
    footer.visibleBackgroundView.alpha = 1.0;
    footer.moreLabel.text = [group footerText];
    [footer applyTheme:self.theme];
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(group);
    switch (group.moreType) {
        case WMFFeedMoreTypeNone:
            return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier forIndexPath:indexPath];
        case WMFFeedMoreTypeLocationAuthorization: {
            WMFTitledExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFTitledExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
            [self configureTitledExploreSectionFooter:footer forSectionAtIndex:indexPath.section];
            return footer;
        }
        default: {
            WMFExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
            [self configureFooter:footer withContentGroup:group];
            @weakify(self);
            footer.whenTapped = ^{
                @strongify(self);
                NSIndexPath *indexPathForSection = [self.fetchedResultsController indexPathForObject:group];
                if (!indexPathForSection) {
                    return;
                }
                [self presentMoreViewControllerForSectionAtIndex:indexPathForSection.row animated:YES];
            };
            return footer;
        }
    }
}

- (void)enableLocationButtonPressed:(UIButton *)sender {
    [[NSUserDefaults wmf_userDefaults] wmf_setExploreDidPromptForLocationAuthorization:YES];
    if ([WMFLocationManager isAuthorizationNotDetermined]) {
        [self.locationManager startMonitoringLocation];
        return;
    }
    [[UIApplication sharedApplication] wmf_openAppSpecificSystemSettings];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    if (!contentGroup) {
        return NO;
    }
    switch (contentGroup.contentGroupKind) {
        case WMFContentGroupKindAnnouncement:
        case WMFContentGroupKindTheme:
        case WMFContentGroupKindNotification:
            return NO;
        default:
            return YES;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    if (!contentGroup) {
        return NO;
    }
    if (contentGroup.contentGroupKind == WMFContentGroupKindAnnouncement) {
        return NO;
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self presentDetailViewControllerForItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - Cells, Headers and Footers

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    WMFExploreCollectionViewCell *placeholderCell = [[nib instantiateWithOwner:nil options:nil] firstObject];
    if (!placeholderCell) {
        return;
    }
    placeholderCell.hidden = YES;
    [self.view insertSubview:placeholderCell atIndex:0]; // so that the trait collections are updated
    [self.placeholderCells setObject:placeholderCell forKey:identifier];
}

- (NSString *)placeholderKeyForSupplementaryViewOfKind:(nonnull NSString *)kind withReuseIdentifier:(nonnull NSString *)identifier {
    return [@[kind, identifier] componentsJoinedByString:@"-"];
}

- (void)registerNib:(UINib *)nib forSupplementaryViewOfKind:(nonnull NSString *)kind withReuseIdentifier:(nonnull NSString *)identifier {
    [self.collectionView registerNib:nib forSupplementaryViewOfKind:kind withReuseIdentifier:identifier];
    WMFExploreCollectionReusableView *placeholderView = [[nib instantiateWithOwner:nil options:nil] firstObject];
    if (!placeholderView) {
        return;
    }
    placeholderView.hidden = YES;
    [self.view insertSubview:placeholderView atIndex:0]; // so that the trait collections are updated
    [self.placeholderViews setObject:placeholderView forKey:[self placeholderKeyForSupplementaryViewOfKind:kind withReuseIdentifier:identifier]];
}

- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    WMFExploreCollectionViewCell *placeholderCell = [[cellClass alloc] initWithFrame:self.view.bounds];
    if (!placeholderCell) {
        return;
    }
    placeholderCell.hidden = YES;
    [self.view insertSubview:placeholderCell atIndex:0]; // so that the trait collections are updated
    [self.placeholderCells setObject:placeholderCell forKey:identifier];
}

- (id)placeholderCellForIdentifier:(NSString *)identifier {
    WMFExploreCollectionViewCell *cell = self.placeholderCells[identifier];
    [cell prepareForReuse];
    return cell;
}

- (id)placeholderForSupplementaryViewOfKind:(nonnull NSString *)kind withReuseIdentifier:(nonnull NSString *)identifier {
    return self.placeholderViews[[self placeholderKeyForSupplementaryViewOfKind:kind withReuseIdentifier:identifier]];
}

- (void)registerCellsAndViews {
    [self registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];
    
    [self registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];
    
    [self registerNib:[WMFTitledExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFTitledExploreSectionFooter wmf_nibName]];
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier];
    
    [self registerClass:[WMFAnnouncementCollectionViewCell class] forCellWithReuseIdentifier:@"WMFAnnouncementCollectionViewCell"];
    
    [self registerClass:[WMFArticleRightAlignedImageCollectionViewCell class] forCellWithReuseIdentifier:@"WMFArticleRightAlignedImageCollectionViewCell"];
    
    [self registerClass:[WMFRankedArticleCollectionViewCell class] forCellWithReuseIdentifier:@"WMFRankedArticleCollectionViewCell"];
    
    [self registerClass:[WMFArticleFullWidthImageCollectionViewCell class] forCellWithReuseIdentifier:@"WMFArticleFullWidthImageCollectionViewCell"];
    
    [self registerClass:[WMFNewsCollectionViewCell class] forCellWithReuseIdentifier:@"WMFNewsCollectionViewCell"];
    
    [self registerClass:[WMFOnThisDayExploreCollectionViewCell class] forCellWithReuseIdentifier:@"WMFOnThisDayExploreCollectionViewCell"];
    
    [self.collectionView registerNib:[WMFNearbyArticleCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName]];
    
    [self.collectionView registerNib:[WMFPicOfTheDayCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName]];
}

- (UIEdgeInsets)readableMargins {
    return [(WMFColumnarCollectionViewLayout *)self.collectionViewLayout readableMargins];
}

- (void)configureArticleCell:(WMFArticleCollectionViewCell *)cell withSection:(WMFContentGroup *)section displayType:(WMFFeedDisplayType)displayType withArticle:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath layoutOnly:(BOOL)layoutOnly {
    if (!article || !section) {
        return;
    }
    cell.layoutMargins = self.readableMargins;
    [cell configureWithArticle:article displayType:displayType index:indexPath.item count:[self numberOfItemsInContentGroup:section] shouldAdjustMargins:YES theme:self.theme layoutOnly:layoutOnly];
    cell.saveButton.analyticsContext = [self analyticsContext];
    cell.saveButton.analyticsContentType = [section analyticsContentType];
}

- (void)configureNearbyCell:(WMFNearbyArticleCollectionViewCell *)cell withArticle:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath {
    cell.layoutMargins = self.readableMargins;
    cell.titleText = article.displayTitle;
    cell.descriptionText = article.capitalizedWikidataDescription;
    [cell setImageURL:[article imageURLForWidth:self.traitCollection.wmf_nearbyThumbnailWidth]];
    [cell applyTheme:self.theme];
    [self updateLocationCell:cell location:article.location];
}

- (void)configurePhotoCell:(WMFPicOfTheDayCollectionViewCell *)cell withImageInfo:(WMFFeedImage *)imageInfo atIndexPath:(NSIndexPath *)indexPath {
    cell.layoutMargins = self.readableMargins;
    [cell setImageURL:imageInfo.imageThumbURL];
    if (imageInfo.imageDescription.length) {
        [cell setDisplayTitle:[imageInfo.imageDescription wmf_stringByRemovingHTML]];
    } else {
        [cell setDisplayTitle:imageInfo.canonicalPageTitle];
    }
    [cell applyTheme:self.theme];
    //    self.referenceImageView = cell.potdImageView;
}

- (void)configureNewsCell:(WMFNewsCollectionViewCell *)cell withContentGroup:(WMFContentGroup *)contentGroup layoutOnly:(BOOL)layoutOnly {
    cell.layoutMargins = self.readableMargins;
    WMFFeedNewsStory *story = (WMFFeedNewsStory *)contentGroup.contentPreview;
    if ([story isKindOfClass:[WMFFeedNewsStory class]]) {
        [cell configureWithStory:story dataStore:self.userStore theme:self.theme layoutOnly:layoutOnly];
    }
}

- (void)configureOnThisDayCell:(WMFOnThisDayExploreCollectionViewCell *)cell withContentGroup:(WMFContentGroup *)contentGroup layoutOnly:(BOOL)layoutOnly {
    cell.layoutMargins = self.readableMargins;
    NSArray *previewEvents = (NSArray *)contentGroup.contentPreview;
    if ([previewEvents isKindOfClass:[NSArray class]]) {
        WMFFeedOnThisDayEvent *event = previewEvents.firstObject;
        WMFFeedOnThisDayEvent *previousEvent = previewEvents.count > 1 ? previewEvents.lastObject : nil;
        if ([event isKindOfClass:[WMFFeedOnThisDayEvent class]] && (previousEvent == nil || [previousEvent isKindOfClass:[WMFFeedOnThisDayEvent class]])) {
            [cell configureWithOnThisDayEvent:event previousEvent:previousEvent dataStore:self.userStore theme:self.theme layoutOnly:layoutOnly];
        }
    }
}

- (void)configureAnnouncementCell:(WMFAnnouncementCollectionViewCell *)cell withContentGroup:(WMFContentGroup *)contentGroup atIndexPath:(NSIndexPath *)indexPath {
    cell.layoutMargins = self.readableMargins;
    WMFFeedDisplayType displayType = [contentGroup displayTypeForItemAtIndex:indexPath.item];
    switch (displayType) {
        case WMFFeedDisplayTypeAnnouncement: {
            WMFAnnouncement *announcement = (WMFAnnouncement *)contentGroup.contentPreview;
            if (![announcement isKindOfClass:[WMFAnnouncement class]]) {
                return;
            }
            if (announcement.imageURL) {
                cell.isImageViewHidden = NO;
                [cell.imageView wmf_setImageWithURL:announcement.imageURL detectFaces:NO failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
            } else {
                cell.isImageViewHidden = YES;
            }
            cell.messageLabel.text = announcement.text;
            [cell.actionButton setTitle:announcement.actionTitle forState:UIControlStateNormal];
            cell.caption = announcement.caption;
        } break;
        case WMFFeedDisplayTypeNotification: {
            cell.isImageViewHidden = NO;
            cell.imageView.image = [UIImage imageNamed:@"feed-card-notification"];
            cell.imageViewDimension = cell.imageView.image.size.height;
            cell.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"feed-news-notification-text", nil, nil, @"Enable notifications to be notified by Wikipedia when articles are trending in the news.", @"Text shown to users to notify them that it is now possible to get notifications for articles related to trending news");
            [cell.actionButton setTitle:WMFLocalizedStringWithDefaultValue(@"feed-news-notification-button-text", nil, nil, @"Turn on notifications", @"Text for button to turn on trending news notifications") forState:UIControlStateNormal];
        } break;
        case WMFFeedDisplayTypeTheme: {
            cell.isImageViewHidden = NO;
            cell.imageView.image = [UIImage imageNamed:@"feed-card-themes"];
            cell.imageViewDimension = cell.imageView.image.size.height;
            cell.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"home-themes-prompt", nil, nil, @"Adjust your Reading preferences including text size and theme from the article tool bar or in your user settings for a more comfortable reading experience.", @"Description on feed card that describes how to adjust reading preferences.");
            [cell.actionButton setTitle:WMFLocalizedStringWithDefaultValue(@"home-themes-action-title", nil, nil, @"Manage preferences", @"Action on the feed card that describes the theme feature. Takes the user to manage theme preferences.") forState:UIControlStateNormal];
        } break;
        default:
            break;
    }
    [cell applyTheme:self.theme];
    cell.delegate = self;
}

- (BOOL)isDisplayingLocationCell {
    __block BOOL hasLocationCell = NO;
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]) {
            hasLocationCell = YES;
            *stop = YES;
        }
        
    }];
    return hasLocationCell;
}

- (void)updateLocationCells {
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:obj];
        if ([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]) {
            WMFArticle *preview = [self articleForIndexPath:obj];
            [self updateLocationCell:(WMFNearbyArticleCollectionViewCell *)cell location:preview.location];
        }
    }];
}

- (void)updateLocationCell:(WMFNearbyArticleCollectionViewCell *)cell location:(CLLocation *)location {
    CLLocation *userLocation = self.locationManager.location;
    if (userLocation == nil) {
        [cell configureForUnknownDistance];
        return;
    }
    [cell setDistance:[userLocation distanceFromLocation:location]];
    [cell setBearing:[userLocation wmf_bearingToLocation:location forCurrentHeading:self.locationManager.heading]];
}

- (void)selectItem:(NSUInteger)item inSection:(NSUInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (NSIndexPath *)topIndexPathToMaintainFocus {
    
    __block NSIndexPath *top = nil;
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        WMFContentGroup *group = [self sectionAtIndex:obj.section];
        if (group.contentGroupKind != WMFContentGroupKindMainPage) {
            return;
        }
        top = obj;
        *stop = YES;
    }];
    
    return top;
}

#pragma mark - Header Action

- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFContentGroup *group = [self sectionAtIndex:section];
    
    switch ([group headerActionType]) {
        case WMFFeedHeaderActionTypeOpenHeaderContent: {
            NSURL *url = [group headerContentURL];
            [self wmf_pushArticleWithURL:url dataStore:self.userStore theme:self.theme animated:YES];
        } break;
        case WMFFeedHeaderActionTypeOpenFirstItem: {
            [self selectItem:0 inSection:section];
        } break;
        case WMFFeedHeaderActionTypeOpenMore: {
            [self presentMoreViewControllerForSectionAtIndex:section animated:YES];
        } break;
        default:
            NSAssert(false, @"Unknown header action");
            break;
    }
}

#pragma mark - More View Controller

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated {
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughMoreInContext:self contentType:group value:group];
    
    UIViewController *vc = [group detailViewControllerWithDataStore:self.userStore siteURL:[self currentSiteURL] theme:self.theme];
    if (!vc) {
        NSAssert(false, @"Missing VC for group: %@", group);
        return;
    }
    [self.navigationController pushViewController:vc animated:animated];
}

- (void)presentMoreViewControllerForSectionAtIndex:(NSUInteger)sectionIndex animated:(BOOL)animated {
    WMFContentGroup *group = [self sectionAtIndex:sectionIndex];
    [self presentMoreViewControllerForGroup:group animated:animated];
}

#pragma mark - Peek View Controller

- (nullable UIViewController *)peekViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath group:(WMFContentGroup *)group sectionCount:(NSInteger)sectionCount peekedHeader:(BOOL)peekedHeader peekedFooter:(BOOL)peekedFooter {
    
    if ((peekedHeader || peekedFooter) && sectionCount != 1) {
        return [group detailViewControllerWithDataStore:self.userStore siteURL:[self currentSiteURL] theme:self.theme];
    }
    
    UIViewController *vc = nil;
    NSURL *articleURL = nil;
    
    switch ([group detailType]) {
        case WMFFeedDetailTypePage:
        case WMFFeedDetailTypePageWithRandomButton: {
            articleURL = [self contentURLForIndexPath:indexPath];
        } break;
        case WMFFeedDetailTypeEvent: {
            articleURL = [self onThisDayArticleURLAtIndexPath:indexPath group:group];
            if (!articleURL) {
                vc = [group detailViewControllerWithDataStore:self.userStore siteURL:[self currentSiteURL] theme:self.theme];
            }
        } break;
        case WMFFeedDetailTypeStory: {
            NSArray<WMFFeedNewsStory *> *stories = (NSArray<WMFFeedNewsStory *> *)group.fullContent.object;
            if (indexPath.item >= stories.count) {
                return nil;
            }
            articleURL = [self inTheNewsArticleURLAtIndexPath:indexPath stories:stories];
            if (!articleURL) {
                vc = [group detailViewControllerWithDataStore:self.userStore siteURL:[self currentSiteURL] theme:self.theme];
            }
        } break;
        case WMFFeedDetailTypeGallery: {
            vc = [[WMFPOTDImageGalleryViewController alloc] initWithDates:@[group.date] theme:self.theme overlayViewTopBarHidden:YES];
        } break;
        default:
            vc = [self detailViewControllerForItemAtIndexPath:indexPath];
    }
    
    if (articleURL) {
        WMFArticleViewController *articleViewController = [[WMFArticleViewController alloc] initWithArticleURL:articleURL dataStore:self.userStore theme:self.theme];
        [articleViewController wmf_addPeekableChildViewControllerFor:articleURL dataStore:self.userStore theme:self.theme];
        vc = articleViewController;
    }
    
    if ([vc conformsToProtocol:@protocol(WMFThemeable)]) {
        [(id<WMFThemeable>)vc applyTheme:self.theme];
    }
    return vc;
}

- (nullable NSURL *)onThisDayArticleURLAtIndexPath:(NSIndexPath *)indexPath group:(WMFContentGroup *)group {
    if (indexPath.length > 2) {
        NSArray *previewEvents = (NSArray *)group.contentPreview;
        WMFFeedOnThisDayEvent *event = nil;
        if ([previewEvents isKindOfClass:[NSArray class]]) {
            event = previewEvents.firstObject;
        }
        if ([event isKindOfClass:WMFFeedOnThisDayEvent.class]) {
            NSInteger articleIndex = [indexPath indexAtPosition:2];
            if (articleIndex < event.articlePreviews.count) {
                WMFFeedArticlePreview *preview = event.articlePreviews[articleIndex];
                return preview.articleURL;
            }
        }
    }
    return nil;
}

- (nullable NSURL *)inTheNewsArticleURLAtIndexPath:(NSIndexPath *)indexPath stories:(NSArray<WMFFeedNewsStory *> *)stories {
    if (indexPath.length > 2) {
        WMFFeedNewsStory *story = stories[indexPath.item];
        NSInteger articleIndex = [indexPath indexAtPosition:2];
        if (articleIndex < story.articlePreviews.count) {
            WMFFeedArticlePreview *preview = story.articlePreviews[articleIndex];
            return preview.articleURL;
        }
    }
    return nil;
}

#pragma mark - Detail View Controller

- (nullable UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    
    UIViewController *vc = nil;
    switch ([group detailType]) {
        case WMFFeedDetailTypePage: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore theme:self.theme];
        } break;
        case WMFFeedDetailTypePageWithRandomButton: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            vc = [[WMFRandomArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore theme:self.theme];
        } break;
        case WMFFeedDetailTypeGallery: {
            vc = [[WMFPOTDImageGalleryViewController alloc] initWithDates:@[group.date] theme:self.theme overlayViewTopBarHidden:NO];
        } break;
        case WMFFeedDetailTypeStory: {
            NSArray<WMFFeedNewsStory *> *stories = (NSArray<WMFFeedNewsStory *> *)group.fullContent.object;
            if (indexPath.item >= stories.count) {
                return nil;
            }
            NSURL *articleURL = [self inTheNewsArticleURLAtIndexPath:indexPath stories:stories];
            if (articleURL) {
                vc = [[WMFArticleViewController alloc] initWithArticleURL:articleURL dataStore:self.userStore theme:self.theme];
                break;
            }
            vc = [[WMFNewsViewController alloc] initWithStories:stories dataStore:self.userStore];
        } break;
        case WMFFeedDetailTypeEvent: {
            NSArray<WMFFeedOnThisDayEvent *> *events = (NSArray<WMFFeedOnThisDayEvent *> *)group.fullContent.object;
            NSURL *articleURL = [self onThisDayArticleURLAtIndexPath:indexPath group:group];
            if (articleURL) {
                vc = [[WMFArticleViewController alloc] initWithArticleURL:articleURL dataStore:self.userStore theme:self.theme];
                break;
            }
            vc = [[WMFOnThisDayViewController alloc] initWithEvents:events dataStore:self.userStore midnightUTCDate:group.midnightUTCDate];
        } break;
        case WMFFeedDetailTypeNone:
            break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
    if ([vc conformsToProtocol:@protocol(WMFThemeable)]) {
        [(id<WMFThemeable>)vc applyTheme:self.theme];
    }
    return vc;
}

- (void)presentDetailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    UIViewController *vc = [self detailViewControllerForItemAtIndexPath:indexPath];
    
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:self contentType:group value:group];
    
    if (vc == nil || vc == self) {
        return;
    }
    
    switch ([group detailType]) {
        case WMFFeedDetailTypePage: {
            [self wmf_pushArticleViewController:(WMFArticleViewController *)vc animated:animated];
        } break;
        case WMFFeedDetailTypePageWithRandomButton: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedDetailTypeGallery: {
            [self presentViewController:vc animated:animated completion:nil];
        } break;
        case WMFFeedDetailTypeStory: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedDetailTypeEvent: {
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
}

#pragma mark - WMFLocationManager

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didUpdateHeading:(CLHeading *)heading {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error {
    //TODO: probably not displaying the error, but maybe?
}

- (void)locationManager:(WMFLocationManager *)controller didChangeEnabledState:(BOOL)enabled {
    [[NSUserDefaults wmf_userDefaults] wmf_setLocationAuthorized:enabled];
    [self.userStore.feedContentController updateNearbyForce:NO completion:NULL];
}

#pragma mark - Previewing

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self
                                                              sourceView:self.collectionView];
    }
                        unavailable:^{
                            [self unregisterPreviewing];
                        }];
}

- (void)unregisterPreviewing {
    if (self.previewingContext) {
        [self unregisterForPreviewingWithContext:self.previewingContext];
        self.previewingContext = nil;
    }
}

#pragma mark - WMFArticlePreviewingActionsDelegate
- (void)readMoreArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController {
    [articleController wmf_removePeekableChildViewControllers];
    [self wmf_pushArticleViewController:articleController animated:YES];
}

- (void)saveArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController didSave:(BOOL)didSave articleURL:(NSURL *)articleURL {
    [self.readingListHintController didSave:didSave articleURL:articleURL theme:self.theme];
}

- (void)shareArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController
                                       shareActivityController:(UIActivityViewController *)shareActivityController {
    [articleController wmf_removePeekableChildViewControllers];
    [self presentViewController:shareActivityController animated:YES completion:NULL];
}

- (void)viewOnMapArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController {
    [articleController wmf_removePeekableChildViewControllers];
    NSURL *placesURL = [NSUserActivity wmf_URLForActivityOfType:WMFUserActivityTypePlaces withArticleURL:articleController.articleURL];
    [[UIApplication sharedApplication] openURL:placesURL options:@{} completionHandler:NULL];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                       viewControllerForLocation:(CGPoint)location {
    UICollectionViewLayoutAttributes *layoutAttributes = nil;
    
    if ([self.collectionViewLayout respondsToSelector:@selector(layoutAttributesAtPoint:)]) {
        layoutAttributes = [(id)self.collectionViewLayout layoutAttributesAtPoint:location];
    }
    
    if (layoutAttributes == nil) {
        return nil;
    }
    
    NSIndexPath *previewIndexPath = layoutAttributes.indexPath;
    NSInteger section = previewIndexPath.section;
    NSInteger sectionCount = [self numberOfItemsInSection:section];
    
    if (previewIndexPath.row >= sectionCount) {
        return nil;
    }
    
    WMFContentGroup *group = [self sectionForIndexPath:previewIndexPath];
    if (!group) {
        return nil;
    }
    self.groupForPreviewedCell = group;
    
    BOOL peekedHeader = [layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader];
    BOOL peekedFooter = [layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter];
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:previewIndexPath];
    previewingContext.sourceRect = cell.frame;
    
    if ([cell isKindOfClass:[WMFSideScrollingCollectionViewCell class]]) { // If possible, sub-item support should be made into a protocol rather than checking the specific class
        WMFSideScrollingCollectionViewCell *sideScrollingCell = (WMFSideScrollingCollectionViewCell *)cell;
        CGPoint pointInCellCoordinates = [self.collectionView convertPoint:location toView:sideScrollingCell];
        NSInteger index = [sideScrollingCell subItemIndexAtPoint:pointInCellCoordinates];
        if (index != NSNotFound) {
            UIView *view = [sideScrollingCell viewForSubItemAtIndex:index];
            CGRect sourceRect = [view convertRect:view.bounds toView:self.collectionView];
            previewingContext.sourceRect = sourceRect;
            NSUInteger indexes[3] = {previewIndexPath.section, previewIndexPath.item, index};
            previewIndexPath = [NSIndexPath indexPathWithIndexes:indexes length:3];
        }
    }
    
    UIViewController *vc = [self peekViewControllerForItemAtIndexPath:previewIndexPath group:group sectionCount:sectionCount peekedHeader:peekedHeader peekedFooter:peekedFooter];
    [[PiwikTracker sharedInstance] wmf_logActionPreviewInContext:self contentType:group];
    
    if ([vc isKindOfClass:[WMFArticleViewController class]]) {
        ((WMFArticleViewController *)vc).articlePreviewingActionsDelegate = self;
    }
    
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit {
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:self contentType:self.groupForPreviewedCell];
    self.groupForPreviewedCell = nil;
    
    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        // Show unobscured article view controller when peeking through.
        [viewControllerToCommit wmf_removePeekableChildViewControllers];
        [self wmf_pushArticleViewController:(WMFArticleViewController *)viewControllerToCommit animated:YES];
    } else if ([viewControllerToCommit isKindOfClass:[WMFColumnarCollectionViewController class]]) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else if (![viewControllerToCommit isKindOfClass:[WMFExploreViewController class]]) {
        if ([viewControllerToCommit isKindOfClass:[WMFImageGalleryViewController class]]) {
            [(WMFImageGalleryViewController *)viewControllerToCommit setOverlayViewTopBarHidden:NO];
        }
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    WMFSectionChange *sectionChange = [WMFSectionChange new];
    sectionChange.type = type;
    sectionChange.sectionIndex = sectionIndex;
    [self.sectionChanges addObject:sectionChange];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    WMFObjectChange *objectChange = [WMFObjectChange new];
    objectChange.type = type;
    objectChange.fromIndexPath = indexPath;
    objectChange.toIndexPath = newIndexPath;
    [self.objectChanges addObject:objectChange];
}

- (void)batchUpdateCollectionView:(NSArray *)previousSectionCounts {
    [self.collectionView performBatchUpdates:^{
        NSMutableIndexSet *deletedSections = [NSMutableIndexSet indexSet];
        NSMutableIndexSet *insertedSections = [NSMutableIndexSet indexSet];
        for (WMFObjectChange *change in self.objectChanges) {
            switch (change.type) {
                case NSFetchedResultsChangeInsert: {
                    NSInteger insertedIndex = change.toIndexPath.row;
                    [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:insertedIndex]];
                    [insertedSections addIndex:insertedIndex];
                } break;
                case NSFetchedResultsChangeDelete: {
                    NSInteger deletedIndex = change.fromIndexPath.row;
                    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:deletedIndex]];
                    [deletedSections addIndex:deletedIndex];
                } break;
                case NSFetchedResultsChangeUpdate: {
                    if (change.toIndexPath && change.fromIndexPath && ![change.toIndexPath isEqual:change.fromIndexPath]) {
                        if ([deletedSections containsIndex:change.fromIndexPath.row]) {
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:change.toIndexPath.row]];
                        } else {
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:change.fromIndexPath.row]];
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:change.toIndexPath.row]];
                        }
                    } else {
                        NSIndexPath *updatedIndexPath = change.toIndexPath ?: change.fromIndexPath;
                        NSInteger sectionIndex = updatedIndexPath.row;
                        if ([insertedSections containsIndex:updatedIndexPath.row]) {
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                        } else {
                            NSInteger previousCount = [previousSectionCounts[sectionIndex] integerValue];
                            NSInteger currentCount = [self.sectionCounts[sectionIndex] integerValue];
                            if (previousCount == currentCount) {
                                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                                continue;
                            }
                            
                            while (previousCount > currentCount) {
                                [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:previousCount - 1 inSection:sectionIndex]]];
                                previousCount--;
                            }
                            
                            while (previousCount < currentCount) {
                                [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:previousCount inSection:sectionIndex]]];
                                previousCount++;
                            }
                            
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                        }
                    }
                } break;
                case NSFetchedResultsChangeMove:
                    [self.collectionView moveSection:change.fromIndexPath.row toSection:change.toIndexPath.row];
                    break;
            }
        }
    }
                                  completion:NULL];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    BOOL shouldReload = self.sectionChanges.count > 0;
    
    NSArray *previousSectionCounts = [self.sectionCounts copy];
    NSInteger previousNumberOfSections = previousSectionCounts.count;
    
    NSInteger sectionDelta = 0;
    BOOL didInsertFirstSection = false;
    for (WMFObjectChange *change in self.objectChanges) {
        switch (change.type) {
            case NSFetchedResultsChangeInsert: {
                sectionDelta++;
                if (change.toIndexPath.section == 0) {
                    didInsertFirstSection = true;
                }
            } break;
            case NSFetchedResultsChangeDelete:
                sectionDelta--;
                break;
            case NSFetchedResultsChangeUpdate:
                break;
            case NSFetchedResultsChangeMove:
                break;
        }
    }
    
    [self updateSectionCounts];
    NSInteger currentNumberOfSections = self.sectionCounts.count;
    BOOL sectionCountsMatch = ((sectionDelta + previousNumberOfSections) == currentNumberOfSections);
    
    if (!sectionCountsMatch) {
        DDLogError(@"Mismatched section update counts: %@ + %@ != %@", @(sectionDelta), @(previousNumberOfSections), @(currentNumberOfSections));
    }
    
    shouldReload = shouldReload || !sectionCountsMatch;
    
    WMFColumnarCollectionViewLayout *layout = (WMFColumnarCollectionViewLayout *)self.collectionViewLayout;
    if (shouldReload) {
        layout.slideInNewContentFromTheTop = NO;
        [self.collectionView reloadData];
    } else {
        if (didInsertFirstSection && sectionDelta > 0 && [previousSectionCounts count] > 0) {
            layout.slideInNewContentFromTheTop = YES;
            [UIView animateWithDuration:0.7 + 0.1 * sectionDelta
                                  delay:0
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 [self batchUpdateCollectionView:previousSectionCounts];
                             }
                             completion:NULL];
        } else {
            layout.slideInNewContentFromTheTop = NO;
            [self batchUpdateCollectionView:previousSectionCounts];
        }
    }
    
    [self.objectChanges removeAllObjects];
    [self.sectionChanges removeAllObjects];
}

#pragma mark - WMFAnnouncementCollectionViewCellDelegate

- (void)announcementCellDidTapDismiss:(WMFAnnouncementCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionDismissInContext:self contentType:group value:group];
    [self dismissAnnouncementCell:cell];
}

- (void)announcementCellDidTapActionButton:(WMFAnnouncementCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionTapThroughInContext:self contentType:group value:group];
    switch (group.contentGroupKind) {
        case WMFContentGroupKindTheme: {
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFNavigateToActivityNotification object:[NSUserActivity wmf_appearanceSettingsActivity]];
            [self dismissAnnouncementCell:cell];
        } break;
        case WMFContentGroupKindNotification: {
            [[WMFNotificationsController sharedNotificationsController] requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error) {
                if (error) {
                    [self wmf_showAlertWithError:error];
                }
            }];
            [[NSUserDefaults wmf_userDefaults] wmf_setInTheNewsNotificationsEnabled:YES];
            [self dismissNotificationCard];
        } break;
        default: {
            WMFAnnouncement *announcement = (WMFAnnouncement *)group.contentPreview;
            NSURL *url = announcement.actionURL;
            [self wmf_openExternalUrl:url];
            [self dismissAnnouncementCell:cell];
        } break;
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)announcementCell:(WMFAnnouncementCollectionViewCell *)cell didTapLinkURL:(NSURL *)url {
    [self wmf_openExternalUrl:url];
}

- (void)dismissAnnouncementCell:(WMFAnnouncementCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    WMFContentGroup *contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    if (!contentGroup) {
        return;
    }
    
    switch (contentGroup.contentGroupKind) {
        case WMFContentGroupKindAnnouncement:
        case WMFContentGroupKindTheme:
        case WMFContentGroupKindNotification: {
            [contentGroup markDismissed];
            [contentGroup updateVisibility];
            NSError *saveError = nil;
            [self.userStore save:&saveError];
            if (saveError) {
                DDLogError(@"Error saving after announcement dismissal: %@", saveError);
            }
        } break;
        default:
            break;
    }
}

#pragma mark - Analytics

- (NSString *)analyticsContext {
    return @"Explore";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

#pragma mark - Load More

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidScroll:scrollView];
    
    if (self.isLoadingOlderContent) {
        return;
    }
    CGFloat ratio = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.size.height);
    if (ratio < 0.8) {
        return;
    }
    
    NSInteger lastGroupIndex = (NSInteger)self.fetchedResultsController.sections.lastObject.numberOfObjects - 1;
    if (lastGroupIndex < 0) {
        return;
    }
    
    WMFContentGroup *lastGroup = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:lastGroupIndex inSection:0]];
    
    NSDate *now = [NSDate date];
    NSDate *midnightUTC = [now wmf_midnightUTCDateFromLocalDate];
    NSDate *lastGroupMidnightUTC = lastGroup.midnightUTCDate;
    
    if (!midnightUTC || !lastGroupMidnightUTC) {
        return;
    }
    
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSInteger days = [calendar wmf_daysFromDate:lastGroupMidnightUTC toDate:midnightUTC];
    if (days >= WMFExploreFeedMaximumNumberOfDays) {
        return;
    }
    
    NSDate *nextOldestDate = [[calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:lastGroupMidnightUTC options:NSCalendarMatchStrictly] wmf_midnightLocalDateForEquivalentUTCDate];
    
    self.loadingOlderContent = YES;
    [self updateFeedSourcesWithDate:nextOldestDate
                      userInitiated:NO
                         completion:^{
                             self.loadingOlderContent = NO;
                         }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillBeginDragging:scrollView];
    [self.readingListHintController scrollViewWillBeginDragging];
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self.navigationBarHider scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidEndScrollingAnimation:scrollView];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewWillScrollToTop:scrollView];
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self.navigationBarHider scrollViewDidScrollToTop:scrollView];
}

- (void)titleBarButtonPressed:(UIButton *)sender {
    [self scrollToTop];
}

#pragma mark - WMFViewController

- (nullable UIScrollView *)scrollView {
    return self.collectionView;
}

- (void)navigationBarHider:(WMFNavigationBarHider *_Nonnull)hider didSetNavigationBarPercentHidden:(CGFloat)didSetNavigationBarPercentHidden extendedViewPercentHidden:(CGFloat)extendedViewPercentHidden animated:(BOOL)animated {
    self.shortTitleButton.alpha = extendedViewPercentHidden;
    self.longTitleButton.alpha = 1.0 - extendedViewPercentHidden;
    self.navigationItem.rightBarButtonItem.customView.alpha = extendedViewPercentHidden;
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    NSUserActivity *searchActivity = [NSUserActivity wmf_searchViewActivity];
    [NSNotificationCenter.defaultCenter postNotificationName:WMFNavigateToActivityNotification object:searchActivity];
    return NO;
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    [super applyTheme:theme];
    
    [self.searchBar setSearchFieldBackgroundImage:theme.searchBarBackgroundImage forState:UIControlStateNormal];
    [self.searchBar wmf_enumerateSubviewTextFields:^(UITextField *textField) {
        textField.textColor = theme.colors.primaryText;
        textField.keyboardAppearance = theme.keyboardAppearance;
        textField.font = [UIFont systemFontOfSize:14];
    }];
    
    self.searchBar.searchTextPositionAdjustment = UIOffsetMake(7, 0);
    self.collectionView.backgroundColor = theme.colors.baseBackground;
    self.view.backgroundColor = theme.colors.baseBackground;
    self.collectionView.indicatorStyle = theme.scrollIndicatorStyle;
    [self.collectionView reloadData];
}

#pragma mark - News Delegate

- (void)sideScrollingCollectionViewCell:(WMFSideScrollingCollectionViewCell *)cell didSelectArticleWithURL:(NSURL *)articleURL {
    if (articleURL == nil) {
        return;
    }
    [self wmf_pushArticleWithURL:articleURL dataStore:self.userStore theme:self.theme animated:YES];
}

#pragma mark - WMFSaveButtonsControllerDelegate

- (void)didSaveArticle:(BOOL)didSave article:(WMFArticle *)article {
    [self.readingListHintController didSave:didSave article:article theme:self.theme];
}

- (void)willUnsaveArticle:(WMFArticle * _Nonnull)article {
    [self.readingListHintController hideHintImmediately];
    [self.readingListActionSheetController showActionSheetFor:article with:self.theme];
}

#pragma mark - WMFReadingListActionSheetControllerDelegate

- (void)readingListActionSheetController:(WMFReadingListActionSheetController *)readingListActionSheetController didSelectUnsaveForArticle:(WMFArticle * _Nonnull)article {
    [self.saveButtonsController updateSavedState];
}

#if DEBUG && DEBUG_CHAOS
- (void)motionEnded:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event {
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
    if (event.subtype != UIEventSubtypeMotionShake) {
        return;
    }
    [self.userStore.feedContentController debugChaos];
}
#endif

@end

NS_ASSUME_NONNULL_END
