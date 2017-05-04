#import "WMFExploreViewController.h"

#import "Wikipedia-Swift.h"

#import <Masonry/Masonry.h>

#import "PiwikTracker+WMFExtensions.h"

#import "MWKDataStore.h"
#import "MWKLanguageLinkController.h"

#import "WMFLocationManager.h"
#import "CLLocation+WMFBearing.h"

#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "MWKHistoryEntry.h"

#import "WMFFeedArticlePreview.h"
#import "WMFFeedNewsStory.h"
#import "WMFFeedImage.h"
#import "WMFAnnouncement.h"

#import "WMFSaveButtonController.h"

#import "WMFColumnarCollectionViewLayout.h"

#import "UIFont+WMFStyle.h"
#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"

#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"
#import "WMFFeedNotificationHeader.h"

#import "WMFLeadingImageTrailingTextButton.h"

#import "WMFArticleListCollectionViewCell.h"
#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFPicOfTheDayCollectionViewCell.h"
#import "WMFNearbyArticleCollectionViewCell.h"
#import "WMFAnnouncementCollectionViewCell.h"

#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFSearch.h"

#import "WMFArticleViewController.h"
#import "WMFImageGalleryViewController.h"
#import "WMFRandomArticleViewController.h"
#import "WMFFirstRandomViewController.h"
#import "WMFMorePageListViewController.h"
#import "WMFSettingsViewController.h"
#import "WMFAnnouncement.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"
#import "WMFChange.h"

#import "WMFCVLAttributes.h"
#import "NSCalendar+WMFCommonCalendars.h"
@import WMF;

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFFeedEmptyHeaderFooterReuseIdentifier = @"WMFFeedEmptyHeaderFooterReuseIdentifier";
const NSInteger WMFExploreFeedMaximumNumberOfDays = 30;

@interface WMFExploreViewController () <WMFLocationManagerDelegate, NSFetchedResultsControllerDelegate, WMFColumnarCollectionViewLayoutDelegate, WMFArticlePreviewingActionsDelegate, UIViewControllerPreviewingDelegate, WMFAnnouncementCollectionViewCellDelegate, UICollectionViewDataSourcePrefetching>

@property (nonatomic, strong) WMFLocationManager *locationManager;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong, nullable) WMFContentGroup *groupForPreviewedCell;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong, nullable) WMFFeedNotificationHeader *notificationHeader;

@property (nonatomic, strong, nullable) AFNetworkReachabilityManager *reachabilityManager;

@property (nonatomic, strong) NSMutableArray<WMFSectionChange *> *sectionChanges;
@property (nonatomic, strong) NSMutableArray<WMFObjectChange *> *objectChanges;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *sectionCounts;

@property (nonatomic, strong) NSMutableDictionary<NSString *, WMFExploreCollectionViewCell *> *placeholderCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, WMFExploreCollectionReusableView *> *placeholderFooters;

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, NSURL *> *prefetchURLsByIndexPath;

@property (nonatomic) CGFloat topInsetBeforeHeader;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cachedHeights;

@property (nonatomic, getter=isLoadingOlderContent) BOOL loadingOlderContent;
@property (nonatomic, getter=isLoadingNewContent) BOOL loadingNewContent;

@end

@implementation WMFExploreViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = WMFLocalizedStringWithDefaultValue(@"home-title", nil, NSBundle.wmf_localizationBundle, @"Explore", @"Title for home interface.\n{{Identical|Explore}}");
    self.sectionChanges = [NSMutableArray arrayWithCapacity:10];
    self.objectChanges = [NSMutableArray arrayWithCapacity:10];
    self.sectionCounts = [NSMutableArray arrayWithCapacity:100];
    self.placeholderCells = [NSMutableDictionary dictionaryWithCapacity:10];
    self.placeholderFooters = [NSMutableDictionary dictionaryWithCapacity:10];
    self.prefetchURLsByIndexPath = [NSMutableDictionary dictionaryWithCapacity:10];
    self.cachedHeights = [NSMutableDictionary dictionaryWithCapacity:10];
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
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b adjustsImageWhenHighlighted];
        UIImage *w = [UIImage imageNamed:@"W"];
        [b setImage:w forState:UIControlStateNormal];
        [b sizeToFit];
        [b addTarget:self action:@selector(titleBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = b;
        self.navigationItem.titleView.isAccessibilityElement = YES;

        self.navigationItem.titleView.accessibilityTraits |= UIAccessibilityTraitHeader;
        self.navigationItem.leftBarButtonItem = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];
    }
    return self;
}

- (void)titleBarButtonPressed {
    [self.collectionView setContentOffset:CGPointZero animated:YES];
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

- (UIBarButtonItem *)settingsBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
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
    NSParameterAssert(group);
    NSArray *content = group.content;
    return [content count] > 0;
}

- (BOOL)isScrolledToTop {
    return self.collectionView.contentOffset.y <= 0;
}

#pragma mark - Actions

- (void)didTapSettingsButton:(UIBarButtonItem *)sender {
    [self showSettings];
}

- (void)showSettings {
    UINavigationController *settingsContainer =
        [[UINavigationController alloc] initWithRootViewController:
                                            [WMFSettingsViewController settingsViewControllerWithDataStore:self.userStore]];
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
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

- (nullable NSArray<id> *)contentForGroup:(WMFContentGroup *)group {
    return group.content;
}

- (nullable NSArray<id> *)contentForSectionAtIndex:(NSUInteger)sectionIndex {
    WMFContentGroup *section = [self sectionAtIndex:sectionIndex];
    return [self contentForGroup:section];
}

- (nullable NSArray<NSURL *> *)contentURLsForGroup:(WMFContentGroup *)group {
    NSArray<id> *content = group.content;

    if ([group contentType] == WMFContentTypeTopReadPreview) {
        content = [content wmf_map:^id(WMFFeedTopReadArticlePreview *obj) {
            return [obj articleURL];
        }];
    } else if ([group contentType] == WMFContentTypeStory) {
        content = [content wmf_map:^id(WMFFeedNewsStory *obj) {
            return [[obj featuredArticlePreview] articleURL] ?: [[[obj articlePreviews] firstObject] articleURL];
        }];
    } else if ([group contentType] != WMFContentTypeURL) {
        content = nil;
    }
    return content;
}

- (nullable NSURL *)contentURLForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    if ([section contentType] == WMFContentTypeTopReadPreview) {

        NSArray<WMFFeedTopReadArticlePreview *> *content = [self contentForSectionAtIndex:indexPath.section];

        if (indexPath.row >= [content count]) {
            return nil;
        }

        return [content[indexPath.row] articleURL];

    } else if ([section contentType] == WMFContentTypeURL) {

        NSArray<NSURL *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            return nil;
        }
        return content[indexPath.row];

    } else if ([section contentType] == WMFContentTypeStory) {
        NSArray<WMFFeedNewsStory *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            return nil;
        }
        return [[content[indexPath.row] featuredArticlePreview] articleURL] ?: [[[content[indexPath.row] articlePreviews] firstObject] articleURL];
    } else {
        return nil;
    }
}

- (nullable NSURL *)imageURLForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    NSURL *articleURL = nil;
    NSInteger width = 0;
    if ([section contentType] == WMFContentTypeTopReadPreview) {

        NSArray<WMFFeedTopReadArticlePreview *> *content = [self contentForSectionAtIndex:indexPath.section];

        if (indexPath.row >= [content count]) {
            articleURL = nil;
        }

        articleURL = [content[indexPath.row] articleURL];
        width = self.traitCollection.wmf_listThumbnailWidth;
    } else if ([section contentType] == WMFContentTypeURL) {

        NSArray<NSURL *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            articleURL = nil;
        }
        articleURL = content[indexPath.row];
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

    } else if ([section contentType] == WMFContentTypeStory) {
        NSArray<WMFFeedNewsStory *> *content = [self contentForSectionAtIndex:indexPath.section];
        if (indexPath.row >= [content count]) {
            articleURL = nil;
        }
        articleURL = [[content[indexPath.row] featuredArticlePreview] articleURL] ?: [[[content[indexPath.row] articlePreviews] firstObject] articleURL];
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
    NSArray<WMFFeedTopReadArticlePreview *> *content = [self contentForSectionAtIndex:indexPath.section];
    if (indexPath.row >= content.count) {
        return nil;
    }
    return [content objectAtIndex:indexPath.row];
}

- (nullable WMFFeedImage *)imageInfoForIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    if ([section contentType] != WMFContentTypeImage) {
        return nil;
    }
    if (indexPath.row >= section.content.count) {
        return nil;
    }
    return (WMFFeedImage *)section.content[indexPath.row];
}

#pragma mark - Refresh Control

- (void)resetRefreshControl {
    if (![self.refreshControl isRefreshing]) {
        return;
    }
    [self.refreshControl endRefreshing];
}

#pragma mark - Notification

- (void)sizeNotificationHeader {

    WMFFeedNotificationHeader *header = self.notificationHeader;
    if (!header.superview) {
        return;
    }

    //First layout pass to get height
    [header mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(-136));
        make.leading.trailing.equalTo(self.collectionView.superview);
    }];

    [header sizeToFit];
    [header setNeedsLayout];
    [header layoutIfNeeded];

    CGRect f = header.frame;

    //Second layout pass to reset the top constraint
    [header mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(-f.size.height));
        make.height.equalTo(@(f.size.height));
        make.leading.trailing.equalTo(self.collectionView.superview);
    }];

    [header sizeToFit];
    [header setNeedsLayout];
    [header layoutIfNeeded];

    UIEdgeInsets insets = self.collectionView.contentInset;
    self.topInsetBeforeHeader = insets.top;
    insets.top = f.size.height;
    self.collectionView.contentInset = insets;
}

- (void)setNotificationHeaderBasedOnSizeClass {
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.notificationHeader = [WMFFeedNotificationHeader wmf_viewFromClassNib];
    } else {
        self.notificationHeader = [[[UINib nibWithNibName:@"WmfFeedNotificationHeaderiPad" bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
    }
}

- (void)showNotificationHeader {

    if (self.notificationHeader) {
        [self.notificationHeader removeFromSuperview];
        self.notificationHeader = nil;
    }

    [self setNotificationHeaderBasedOnSizeClass];

    WMFFeedNotificationHeader *header = self.notificationHeader;
    [self.collectionView addSubview:self.notificationHeader];
    [self sizeNotificationHeader];

    [header.enableNotificationsButton addTarget:self action:@selector(enableNotificationsButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    [[NSUserDefaults wmf_userDefaults] wmf_setDidShowNewsNotificationCardInFeed:YES];

    if (self.isScrolledToTop) {
        [self.collectionView setContentOffset:CGPointMake(0, 0 - header.frame.size.height) animated:YES];
    }
}

- (void)enableNotificationsButtonPressed {
    [[PiwikTracker sharedInstance] wmf_logActionEnableInContext:self.notificationHeader contentType:self.notificationHeader];
    [[WMFNotificationsController sharedNotificationsController] requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error) {
        if (error) {
            [self wmf_showAlertWithError:error];
        }
    }];
    [[NSUserDefaults wmf_userDefaults] wmf_setInTheNewsNotificationsEnabled:YES];
    [self showHideNotificationIfNeccesaryUserInitiated:YES];
}

- (void)showHideNotificationIfNeccesaryUserInitiated:(BOOL)userInitiated {
    if (self.numberOfSectionsInExploreFeed == 0) {
        return;
    }

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionLessThan:10]) {
        return;
    }

    if (![[NSUserDefaults wmf_userDefaults] wmf_inTheNewsNotificationsEnabled] && ![[NSUserDefaults wmf_userDefaults] wmf_didShowNewsNotificationCardInFeed]) {
        [self showNotificationHeader];

    } else if (userInitiated) {

        if (self.notificationHeader) {

            [UIView animateWithDuration:0.3
                animations:^{

                    UIEdgeInsets insets = self.collectionView.contentInset;
                    insets.top = self.topInsetBeforeHeader;
                    self.collectionView.contentInset = insets;

                    self.notificationHeader.alpha = 0.0;

                }
                completion:^(BOOL finished) {

                    [self.notificationHeader removeFromSuperview];
                    self.notificationHeader = nil;

                }];
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellsAndViews];
    self.collectionView.scrollsToTop = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if ([self.collectionView respondsToSelector:@selector(setPrefetchDataSource:)]) {
        self.collectionView.prefetchDataSource = self;
        self.collectionView.prefetchingEnabled = YES;
    }

    [self setupRefreshControl];
}

- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion {
    [self.userStore.feedContentController updateFeedSourcesWithDate:date
                                                      userInitiated:wasUserInitiated
                                                         completion:^{
                                                             WMFAssertMainThread(@"Completion is assumed to be called on the main thread.");
                                                             [self resetRefreshControl];

                                                             if (date == nil) { //only hide on a new content update
                                                                 [self showHideNotificationIfNeccesaryUserInitiated:wasUserInitiated];
                                                                 [self startMonitoringReachabilityIfNeeded];
                                                                 [self showOfflineEmptyViewIfNeeded];
                                                             }
                                                             if (completion) {
                                                                 completion();
                                                             }
                                                         }];
}

- (void)updateFeedSourcesUserInititated:(BOOL)wasUserInitiated {
    if (self.isLoadingNewContent) {
        return;
    }
    self.loadingNewContent = YES;
    if (!self.refreshControl.isRefreshing) {
        [self.refreshControl beginRefreshing];
        if (self.isScrolledToTop && self.numberOfSectionsInExploreFeed == 0) {
            self.collectionView.contentOffset = CGPointMake(0, 0 - self.refreshControl.frame.size.height);
        }
    }
    [self updateFeedSourcesWithDate:nil
                      userInitiated:wasUserInitiated
                         completion:^{
                             self.loadingNewContent = NO;
                         }];
}

- (void)refreshControlActivated {
    [self updateFeedSourcesUserInititated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    [self showHideNotificationIfNeccesaryUserInitiated:NO];
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        cell.selected = NO;
    }

    if (!self.reachabilityManager) {
        self.reachabilityManager = [AFNetworkReachabilityManager manager];
    }

    if (!self.fetchedResultsController) {
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

    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      @strongify(self);
                                                      [self.collectionView reloadData];
                                                  }];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)resetLayoutCache {
    [self.cachedHeights removeAllObjects];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [self resetLayoutCache];
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.notificationHeader) {
        [self showNotificationHeader];
    }
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
                        [self updateFeedSourcesUserInititated:NO];
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
        [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoFeed];
    }
}

- (NSInteger)numberOfItemsInContentGroup:(WMFContentGroup *)contentGroup {
    NSParameterAssert(contentGroup);
    NSArray *feedContent = contentGroup.content;
    return MIN([feedContent count], [contentGroup maxNumberOfCells]);
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

    switch ([contentGroup displayType]) {
        case WMFFeedDisplayTypePage: {
            WMFArticleListCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureListCell:cell withArticle:article atIndexPath:indexPath];
            return cell;
        } break;
        case WMFFeedDisplayTypePageWithPreview: {
            WMFArticlePreviewCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePreviewCell:cell withSection:contentGroup withArticle:article atIndexPath:indexPath layoutOnly:NO];
            return cell;
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            WMFNearbyArticleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureNearbyCell:cell withArticle:article atIndexPath:indexPath];
            return cell;

        } break;
        case WMFFeedDisplayTypePhoto: {
            WMFFeedImage *imageInfo = [self imageInfoForIndexPath:indexPath];
            WMFPicOfTheDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePhotoCell:cell withImageInfo:imageInfo atIndexPath:indexPath];
            return cell;
        } break;
        case WMFFeedDisplayTypeStory: {
            InTheNewsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[InTheNewsCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureStoryCell:cell withSection:contentGroup article:article atIndexPath:indexPath];
            return cell;
        } break;

        case WMFFeedDisplayTypeAnnouncement: {
            WMFAnnouncementCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFAnnouncementCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureAnouncementCell:cell withSection:contentGroup atIndexPath:indexPath];

            return cell;
        } break;
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

#pragma mark - UICollectionViewDelegate

- (WMFLayoutEstimate)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    WMFLayoutEstimate estimate;
    switch ([section displayType]) {
        case WMFFeedDisplayTypePage: {
            estimate.height = [WMFArticleListCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePageWithPreview: {
            WMFArticle *article = [self articleForIndexPath:indexPath];
            NSString *key = article.key;
            NSString *cacheKey = [NSString stringWithFormat:@"%@-%lli", key, (long long)columnWidth];
            NSNumber *cachedValue = [self.cachedHeights objectForKey:cacheKey];
            if (cachedValue) {
                estimate.height = [cachedValue doubleValue];
                estimate.precalculated = YES;
                break;
            }
            NSURL *imageURL = [article imageURLForWidth:self.traitCollection.wmf_leadImageWidth];
            CGFloat estimatedHeight = [WMFArticlePreviewCollectionViewCell estimatedRowHeightWithImage:imageURL != nil];
            CGRect frameToFit = CGRectMake(0, 0, columnWidth, estimatedHeight);
            WMFArticlePreviewCollectionViewCell *cell = [self placeholderCellForIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName]];
            cell.frame = frameToFit;
            [self configurePreviewCell:cell withSection:section withArticle:article atIndexPath:indexPath layoutOnly:YES];
            WMFCVLAttributes *attributesToFit = [WMFCVLAttributes new];
            attributesToFit.frame = frameToFit;
            UICollectionViewLayoutAttributes *attributes = [cell preferredLayoutAttributesFittingAttributes:attributesToFit];
            estimate.height = attributes.frame.size.height;
            estimate.precalculated = YES;
            [self.cachedHeights setObject:@(estimate.height) forKey:cacheKey];
        } break;
        case WMFFeedDisplayTypePageWithLocation: {
            estimate.height = [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypePhoto: {
            estimate.height = [WMFPicOfTheDayCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypeStory: {
            estimate.height = [InTheNewsCollectionViewCell estimatedRowHeight];
        } break;
        case WMFFeedDisplayTypeAnnouncement: {
            WMFAnnouncement *announcement = (WMFAnnouncement *)section.content.firstObject;
            CGFloat estimatedHeight = [WMFAnnouncementCollectionViewCell estimatedRowHeightWithImage:announcement.imageURL != nil];
            CGRect frameToFit = CGRectMake(0, 0, columnWidth, estimatedHeight);
            WMFAnnouncementCollectionViewCell *cell = [self placeholderCellForIdentifier:[WMFAnnouncementCollectionViewCell wmf_nibName]];
            cell.frame = frameToFit;
            [self configureAnouncementCell:cell withSection:section atIndexPath:indexPath];
            WMFCVLAttributes *attributesToFit = [WMFCVLAttributes new];
            attributesToFit.frame = frameToFit;
            UICollectionViewLayoutAttributes *attributes = [cell preferredLayoutAttributesFittingAttributes:attributesToFit];
            estimate.height = attributes.frame.size.height;
            estimate.precalculated = YES;
        } break;
        default:
            NSAssert(false, @"Unknown display Type");
            estimate.height = [WMFArticleListCollectionViewCell estimatedRowHeight];
            break;
    }
    return estimate;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *sectionObject = [self sectionAtIndex:section];
    if ([sectionObject headerType] == WMFFeedHeaderTypeNone) {
        return 0.0;
    } else {
        return 69.0;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup *sectionObject = [self sectionAtIndex:section];
    if ([sectionObject moreType] == WMFFeedMoreTypeNone) {
        return 0.0;
    } else if ([sectionObject moreType] == WMFFeedMoreTypeLocationAuthorization) {
        CGRect frameToFit = CGRectMake(0, 0, columnWidth, 170);
        WMFExploreCollectionReusableView *footer = [self placeholderFooterForIdentifier:[WMFTitledExploreSectionFooter wmf_nibName]];
        footer.frame = frameToFit;
        WMFCVLAttributes *attributesToFit = [WMFCVLAttributes new];
        attributesToFit.frame = frameToFit;
        UICollectionViewLayoutAttributes *attributes = [footer preferredLayoutAttributesFittingAttributes:attributesToFit];
        CGFloat height = attributes.frame.size.height;
        return height;
    } else {
        return 50.0;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index {
    WMFContentGroup *section = [self sectionAtIndex:index];
    return [section prefersWiderColumn];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    [[PiwikTracker sharedInstance] wmf_logActionImpressionInContext:self contentType:section value:section];

    if (![WMFLocationManager isAuthorized]) {
        return;
    }

    if ([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]] || [self isDisplayingLocationCell]) {
        [self.locationManager startMonitoringLocation];
    } else {
        [self.locationManager stopMonitoringLocation];
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *section = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(section);

    if ([section headerType] == WMFFeedHeaderTypeNone) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier forIndexPath:indexPath];
    }
    NSParameterAssert([section headerIcon]);
    NSParameterAssert([section headerTitle]);
    NSParameterAssert([section headerSubTitle]);

    WMFExploreSectionHeader *header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];

    header.image = [[section headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.imageTintColor = [section headerIconTintColor];
    header.imageBackgroundColor = [section headerIconBackgroundColor];

    header.title = [[section headerTitle] mutableCopy];
    [header setTitleColor:[section headerTitleColor]];

    header.subTitle = [[section headerSubTitle] mutableCopy];
    [header setSubTitleColor:[section headerSubTitleColor]];

    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        NSIndexPath *indexPathForSection = [self.fetchedResultsController indexPathForObject:section];
        if (!indexPathForSection) {
            return;
        }
        [self didTapHeaderInSection:indexPathForSection.row];
    };

    if (([section blackListOptions] & WMFFeedBlacklistOptionSection) || (([section blackListOptions] & WMFFeedBlacklistOptionContent) && [section headerContentURL])) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton removeTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        header.rightButton.tag = indexPath.section;
        [header.rightButton addTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton removeTarget:self action:@selector(headerRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }

    return header;
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
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"home-hide-suggestion-prompt", nil, NSBundle.wmf_localizationBundle, @"Hide this suggestion", @"Title of button shown for users to confirm the hiding of a suggestion in the explore feed")
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [self.userStore setIsExcludedFromFeed:YES withArticleURL:url];
                                                        [self.userStore.viewContext removeContentGroup:section];
                                                    }]];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"home-hide-suggestion-cancel", nil, NSBundle.wmf_localizationBundle, @"Cancel", @"Title of the button for cancelling the hiding of an explore feed suggestion\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
            return sheet;
        }
        case WMFContentGroupKindLocationPlaceholder: {
            UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"explore-nearby-placeholder-dismiss", nil, NSBundle.wmf_localizationBundle, @"Dismiss", @"Action button that will dismiss the nearby placeholder\n{{Identical|Dismiss}}")
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                        [[NSUserDefaults wmf_userDefaults] wmf_setExploreDidPromptForLocationAuthorization:YES];
                                                        section.wasDismissed = YES;
                                                        [section updateVisibility];
                                                    }]];
            [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"explore-nearby-placeholder-cancel", nil, NSBundle.wmf_localizationBundle, @"Cancel", @"Action button that will cancel dismissal of the nearby placeholder\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
            return sheet;
        }
        default:
            return nil;
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(group);
    switch (group.moreType) {
        case WMFFeedMoreTypeNone:
            return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier forIndexPath:indexPath];
        case WMFFeedMoreTypeLocationAuthorization: {
            WMFTitledExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFTitledExploreSectionFooter wmf_nibName] forIndexPath:indexPath];

            for (UIGestureRecognizer *gr in footer.gestureRecognizers) {
                [footer removeGestureRecognizer:gr];
            }
            UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePromptForLocationAccessGestureRecognizer:)];
            [footer addGestureRecognizer:tapGR];
            return footer;
        }
        default: {
            WMFExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
            footer.visibleBackgroundView.alpha = 1.0;
            footer.moreLabel.text = [group footerText];
            footer.moreLabel.textColor = [UIColor wmf_exploreSectionFooterText];
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

- (void)handlePromptForLocationAccessGestureRecognizer:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state != UIGestureRecognizerStateRecognized) {
        return;
    }
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
    if (contentGroup.contentGroupKind == WMFContentGroupKindAnnouncement) {
        return NO;
    } else {
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
    [self.view insertSubview:placeholderCell atIndex:0];
    [self.placeholderCells setObject:placeholderCell forKey:identifier];
}

- (id)placeholderCellForIdentifier:(NSString *)identifier {
    return self.placeholderCells[identifier];
}

- (void)registerNib:(UINib *)nib forFooterWithReuseIdentifier:(NSString *)identifier {
    [self.collectionView registerNib:nib forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier];
    WMFExploreCollectionReusableView *placeholderView = [[nib instantiateWithOwner:nil options:nil] firstObject];
    if (!placeholderView) {
        return;
    }
    placeholderView.hidden = YES;
    [self.view insertSubview:placeholderView atIndex:0];
    [self.placeholderFooters setObject:placeholderView forKey:identifier];
}

- (id)placeholderFooterForIdentifier:(NSString *)identifier {
    return self.placeholderFooters[identifier];
}

- (void)registerCellsAndViews {
    [self.collectionView registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self.collectionView registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];

    [self registerNib:[WMFTitledExploreSectionFooter wmf_classNib] forFooterWithReuseIdentifier:[WMFTitledExploreSectionFooter wmf_nibName]];

    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyHeaderFooterReuseIdentifier];

    [self registerNib:[WMFAnnouncementCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFAnnouncementCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFArticleListCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName]];

    [self registerNib:[WMFArticlePreviewCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFNearbyArticleCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[WMFPicOfTheDayCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName]];

    [self.collectionView registerNib:[InTheNewsCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[InTheNewsCollectionViewCell wmf_nibName]];
}

- (void)configureListCell:(WMFArticleListCollectionViewCell *)cell withArticle:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = article.displayTitle;
    cell.titleLabel.accessibilityLanguage = article.URL.wmf_language;
    cell.descriptionText = [article.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    NSURL *imageURL = [article imageURLForWidth:self.traitCollection.wmf_listThumbnailWidth];
    [cell setImageURL:imageURL];
}

- (void)configurePreviewCell:(WMFArticlePreviewCollectionViewCell *)cell withSection:(WMFContentGroup *)section withArticle:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath layoutOnly:(BOOL)layoutOnly {
    cell.titleText = article.displayTitle;
    cell.descriptionText = [article.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    cell.snippetText = article.snippet;
    NSURL *imageURL = [article imageURLForWidth:self.traitCollection.wmf_leadImageWidth];
    if (layoutOnly) {
        if (imageURL) {
            [cell restoreImageToFullHeight];
        } else {
            [cell collapseImageHeightToZero];
        }
    } else {
        [cell setImageURL:imageURL];
        [cell setSaveableURL:article.URL savedPageList:self.userStore.savedPageList];
        cell.saveButtonController.analyticsContext = [self analyticsContext];
        cell.saveButtonController.analyticsContentType = [section analyticsContentType];
    }
}

- (void)configureNearbyCell:(WMFNearbyArticleCollectionViewCell *)cell withArticle:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath {
    cell.titleText = article.displayTitle;
    cell.descriptionText = [article.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:[article imageURLForWidth:self.traitCollection.wmf_nearbyThumbnailWidth]];
    [self updateLocationCell:cell location:article.location];
}

- (void)configurePhotoCell:(WMFPicOfTheDayCollectionViewCell *)cell withImageInfo:(WMFFeedImage *)imageInfo atIndexPath:(NSIndexPath *)indexPath {
    [cell setImageURL:imageInfo.imageThumbURL];
    if (imageInfo.imageDescription.length) {
        [cell setDisplayTitle:[imageInfo.imageDescription wmf_stringByRemovingHTML]];
    } else {
        [cell setDisplayTitle:imageInfo.canonicalPageTitle];
    }
    //    self.referenceImageView = cell.potdImageView;
}

- (void)configureStoryCell:(InTheNewsCollectionViewCell *)cell withSection:(WMFContentGroup *)section article:(WMFArticle *)article atIndexPath:(NSIndexPath *)indexPath {
    NSArray<WMFFeedNewsStory *> *stories = [self contentForGroup:section];
    if (indexPath.item >= stories.count) {
        return;
    }
    WMFFeedNewsStory *story = stories[indexPath.item];
    cell.bodyHTML = story.storyHTML;

    cell.imageURL = [article imageURLForWidth:self.traitCollection.wmf_nearbyThumbnailWidth];
}

- (void)configureAnouncementCell:(WMFAnnouncementCollectionViewCell *)cell withSection:(WMFContentGroup *)section atIndexPath:(NSIndexPath *)indexPath {
    NSArray<WMFAnnouncement *> *announcements = [self contentForGroup:section];
    if (indexPath.item >= announcements.count) {
        return;
    }
    WMFAnnouncement *announcement = announcements[indexPath.item];
    [cell setImageURL:announcement.imageURL];
    [cell setMessageText:announcement.text];
    [cell setActionText:announcement.actionTitle];
    [cell setCaption:announcement.caption];
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
            [self wmf_pushArticleWithURL:url dataStore:self.userStore animated:YES];
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
    NSArray<NSURL *> *URLs = [self contentURLsForGroup:group];
    NSAssert([[URLs firstObject] isKindOfClass:[NSURL class]], @"Attempting to present More VC with somehting other than URLs");
    if (![[URLs firstObject] isKindOfClass:[NSURL class]]) {
        return;
    }

    switch (group.moreType) {
        case WMFFeedMoreTypePageList: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore];
            vc.cellType = WMFMorePageListCellTypeNormal;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageListWithPreview: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore];
            vc.cellType = WMFMorePageListCellTypePreview;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageListWithLocation: {
            WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore];
            vc.cellType = WMFMorePageListCellTypeLocation;
            [self.navigationController pushViewController:vc animated:animated];
        } break;
        case WMFFeedMoreTypePageWithRandomButton: {
            WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self currentSiteURL] dataStore:self.userStore];
            [self.navigationController pushViewController:vc animated:animated];
        } break;

        default:
            NSAssert(false, @"Unknown More Type");
            break;
    }
}

- (void)presentMoreViewControllerForSectionAtIndex:(NSUInteger)sectionIndex animated:(BOOL)animated {
    WMFContentGroup *group = [self sectionAtIndex:sectionIndex];
    [self presentMoreViewControllerForGroup:group animated:animated];
}

#pragma mark - Detail View Controller

- (nullable UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup *group = [self sectionAtIndex:indexPath.section];

    switch ([group detailType]) {
        case WMFFeedDetailTypePage: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore];
            return vc;
        } break;
        case WMFFeedDetailTypePageWithRandomButton: {
            NSURL *url = [self contentURLForIndexPath:indexPath];
            WMFRandomArticleViewController *vc = [[WMFRandomArticleViewController alloc] initWithArticleURL:url dataStore:self.userStore];
            return vc;
        } break;
        case WMFFeedDetailTypeGallery: {
            return [[WMFPOTDImageGalleryViewController alloc] initWithDates:@[group.date]];
        } break;
        case WMFFeedDetailTypeStory: {
            NSArray<WMFFeedNewsStory *> *stories = [self contentForGroup:group];
            if (indexPath.item >= stories.count) {
                return nil;
            }
            WMFFeedNewsStory *story = stories[indexPath.item];
            InTheNewsViewController *vc = [self inTheNewsViewControllerForStory:story date:group.date];
            return vc;
        } break;
        case WMFFeedDetailTypeNone:
            break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
    return nil;
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
    [self wmf_pushArticleViewController:articleController animated:YES];
}

- (void)shareArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController
                                       shareActivityController:(UIActivityViewController *)shareActivityController {
    [self presentViewController:shareActivityController animated:YES completion:NULL];
}

- (void)viewOnMapArticlePreviewActionSelectedWithArticleController:(WMFArticleViewController *)articleController {
    NSURL *placesURL = [NSUserActivity wmf_URLForActivityOfType:WMFUserActivityTypePlaces withArticleURL:articleController.articleURL];
    [[UIApplication sharedApplication] openURL:placesURL];
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

    if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter] && sectionCount > 0) {
        //preview the last item in the section when tapping the footer
        previewIndexPath = [NSIndexPath indexPathForItem:sectionCount - 1 inSection:section];
    }

    if (previewIndexPath.row >= sectionCount) {
        return nil;
    }

    WMFContentGroup *group = [self sectionForIndexPath:previewIndexPath];
    if (!group) {
        return nil;
    }
    self.groupForPreviewedCell = group;

    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:previewIndexPath].frame;

    UIViewController *vc = [self detailViewControllerForItemAtIndexPath:previewIndexPath];
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
        [self wmf_pushArticleViewController:(WMFArticleViewController *)viewControllerToCommit animated:YES];
    } else if ([viewControllerToCommit isKindOfClass:[InTheNewsViewController class]]) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else if (![viewControllerToCommit isKindOfClass:[WMFExploreViewController class]]) {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - In The News

- (InTheNewsViewController *)inTheNewsViewControllerForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date {
    InTheNewsViewController *vc = [[InTheNewsViewController alloc] initWithStory:story dataStore:self.userStore];
    NSString *format = WMFLocalizedStringWithDefaultValue(@"in-the-news-title-for-date", nil, NSBundle.wmf_localizationBundle, @"News on %1$@", @"Title for news on a given date - %1$@ is replaced with the date");
    if (format && date) {
        NSString *dateString = [[NSDateFormatter wmf_shortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date];
        NSString *title = [NSString localizedStringWithFormat:format, dateString];
        vc.title = title;
    } else {
        vc.title = WMFLocalizedStringWithDefaultValue(@"in-the-news-title", nil, NSBundle.wmf_localizationBundle, @"In the news", @"Title for the 'In the news' notification & feed section");
    }
    return vc;
}

- (void)showInTheNewsForStory:(WMFFeedNewsStory *)story date:(nullable NSDate *)date animated:(BOOL)animated {
    InTheNewsViewController *vc = [self inTheNewsViewControllerForStory:story date:date];
    [self.navigationController pushViewController:vc animated:animated];
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
    NSArray<WMFAnnouncement *> *announcements = [self contentForGroup:group];
    if (indexPath.item >= announcements.count) {
        return;
    }
    WMFAnnouncement *announcement = announcements[indexPath.item];
    NSURL *url = announcement.actionURL;
    [self wmf_openExternalUrl:url];
    [self dismissAnnouncementCell:cell];
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
    if (contentGroup.contentGroupKind != WMFContentGroupKindAnnouncement) {
        return;
    }
    [contentGroup markDismissed];
    [contentGroup updateVisibility];
    NSError *saveError = nil;
    [self.userStore save:&saveError];
    if (saveError) {
        DDLogError(@"Error saving after announcement dismissal: %@", saveError);
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
    if (self.isLoadingOlderContent) {
        return;
    }
    CGFloat ratio = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.size.height);
    if (ratio < 0.8) {
        return;
    }

    NSInteger lastGroupIndex = self.fetchedResultsController.sections.lastObject.numberOfObjects - 1;
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

#if DEBUG
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
