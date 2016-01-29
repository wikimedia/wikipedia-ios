#import "WMFExploreViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <BlocksKit/BlocksKit+UIKit.h>
@import Tweaks;
@import SSDataSources;
#import "PiwikTracker+WMFExtensions.h"
#import <PromiseKit/SCNetworkReachability+AnyPromise.h>

// Sections
#import "WMFMainPageSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRelatedSectionController.h"
#import "WMFContinueReadingSectionController.h"
#import "WMFRandomSectionController.h"
#import "WMFFeaturedArticleSectionController.h"
#import "SSSectionedDataSource+WMFSectionConvenience.h"
#import "WMFExploreSectionSchema.h"
#import "WMFExploreSection.h"
#import "WMFPictureOfTheDaySectionController.h"

// Models
#import "WMFAsyncBlockOperation.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "MWKSite.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKLocationSearchResult.h"
#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"

// Views
#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"
#import "UITableView+WMFLockedUpdates.h"

// Child View Controllers
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFArticleContainerViewController.h"
#import "WMFSettingsViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFTitleListDataSource.h"
#import "WMFArticleListTableViewController.h"

// Controllers
#import "WMFRelatedSectionBlackList.h"
#import "UIViewController+WMFArticlePresentation.h"

static DDLogLevel const WMFExploreVCLogLevel = DDLogLevelInfo;
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFExploreVCLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController ()
<WMFExploreSectionSchemaDelegate,
 WMFExploreSectionControllerDelegate,
 UIViewControllerPreviewingDelegate,
 WMFAnalyticsLogging>

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

@property (nonatomic, strong, null_resettable) WMFExploreSectionSchema* schemaManager;

@property (nonatomic, strong, null_resettable) WMFNearbySectionController* nearbySectionController;
@property (nonatomic, strong) NSMutableDictionary* sectionControllers;

@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong) NSMutableDictionary* sectionLoadErrors;

@property (nonatomic, strong, nullable) MWKTitle* previewingTitle;
@property (nonatomic, strong, nullable) id<WMFExploreSectionController> sectionOfPreviewingTitle;

@end

@implementation WMFExploreViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b adjustsImageWhenHighlighted];
        UIImage* w = [UIImage imageNamed:@"W"];
        [b setImage:w forState:UIControlStateNormal];
        [b sizeToFit];
        @weakify(self);
        [b bk_addEventHandler:^(id sender) {
            @strongify(self);
            [self.tableView setContentOffset:CGPointZero animated:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView                        = b;
        self.navigationItem.titleView.isAccessibilityElement = YES;
        self.navigationItem.titleView.accessibilityLabel     = MWLocalizedString(@"home-accessibility-label", nil);
        self.navigationItem.titleView.accessibilityTraits   |= UIAccessibilityTraitHeader;
        self.navigationItem.leftBarButtonItem                = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem               = [self wmf_searchBarButtonItemWithDelegate:self];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = MWLocalizedString(@"home-title", nil);
}

#pragma mark - Accessors

- (MWKSavedPageList*)savedPages {
    return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryList*)recentPages {
    return self.dataStore.userDataStore.historyList;
}

- (UIBarButtonItem*)settingsBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (void)setSearchSite:(MWKSite*)searchSite {
    NSParameterAssert(self.dataStore);
    [self setSearchSite:self.searchSite dataStore:self.dataStore];
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite dataStore:(MWKDataStore* _Nonnull)dataStore {
    if ([_searchSite isEqualToSite:searchSite]) {
        return;
    }

    NSParameterAssert(searchSite);
    NSParameterAssert(dataStore);

    _searchSite = searchSite;
    _dataStore  = dataStore;

    self.schemaManager           = nil;
    self.nearbySectionController = nil;

    if ([self.sectionControllers count] > 0) {
        [self updateSectionSchemaIfNeeded];
        [self reloadSectionControllers];
    }
}

- (WMFExploreSectionSchema*)schemaManager {
    if (!_schemaManager) {
        _schemaManager = [WMFExploreSectionSchema schemaWithSite:self.searchSite
                                                      savedPages:self.savedPages
                                                         history:self.recentPages
                                                       blackList:[WMFRelatedSectionBlackList sharedBlackList]];
        _schemaManager.delegate = self;
    }
    return _schemaManager;
}

- (WMFNearbySectionController*)nearbySectionController {
    if (!_nearbySectionController) {
        _nearbySectionController = [[WMFNearbySectionController alloc]
                                    initWithSite:self.searchSite
                                       dataStore:self.dataStore];
    }
    return _nearbySectionController;
}

- (SSSectionedDataSource*)dataSource {
    if (!_dataSource) {
        _dataSource                           = [[SSSectionedDataSource alloc] init];
        _dataSource.shouldRemoveEmptySections = NO;
    }
    return _dataSource;
}

- (NSMutableDictionary*)sectionControllers {
    if (!_sectionControllers) {
        _sectionControllers = [NSMutableDictionary new];
    }
    return _sectionControllers;
}

- (BOOL)isDisplayingCellsForSectionController:(id<WMFExploreSectionController>)controller {
    NSInteger sectionIndex = [self indexForSectionController:controller];
    if (sectionIndex == NSNotFound) {
        return NO;
    }
    return [self.tableView.indexPathsForVisibleRows bk_any:^BOOL (NSIndexPath* indexPath) {
        return indexPath.section == sectionIndex;
    }];
}

#pragma mark - Actions

- (void)didTapSettingsButton:(UIBarButtonItem*)sender {
    UINavigationController* settingsContainer =
        [[UINavigationController alloc] initWithRootViewController:
         [WMFSettingsViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl bk_addEventHandler:^(id sender) {
        [self updateSectionSchemaForce:YES];
    } forControlEvents:UIControlEventValueChanged];

    [self resetRefreshControlWithCompletion:NULL];

    self.tableView.dataSource                   = nil;
    self.tableView.delegate                     = nil;
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 52.0;
    self.tableView.sectionFooterHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 78.0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterForegroundWithNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tweaksDidChangeWithNotification:)
                                                 name:FBTweakShakeViewControllerDidDismissNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.searchSite);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    [super viewDidAppear:animated];

    [self configureDataSourceIfNeeded];

    if ([self isDisplayingCellsForSectionController:self.nearbySectionController]) {
        [self.nearbySectionController startMonitoringLocation];
    }

    if (self.previewingTitle) {
        [[PiwikTracker sharedInstance] wmf_logActionPreviewDismissedForTitle:self.previewingTitle fromSource:self];
        self.previewingTitle = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // stop location manager from updating.
    [self.nearbySectionController stopMonitoringLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterForPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    } unavailable:^{
        [self unregisterForPreviewing];
    }];
}

- (void)unregisterForPreviewing {
    if (self.previewingContext) {
        [self unregisterForPreviewingWithContext:self.previewingContext];
        self.previewingContext = nil;
    }
}

#pragma mark - Notifications

- (void)applicationDidEnterForegroundWithNotification:(NSNotification*)note {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }

    [self updateSectionSchemaIfNeeded];
}

#pragma mark - Tweaks

- (void)tweaksDidChangeWithNotification:(NSNotification*)note {
    [self updateSectionSchemaIfNeeded];
}

#pragma mark - Offline Handling

- (void)showOfflineEmptyViewAndReloadWhenReachable {
    NSParameterAssert(self.isViewLoaded && self.view.superview);

    [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoFeed];

    @weakify(self);
    SCNetworkReachability().then(^{
        @strongify(self);
        [self wmf_hideEmptyView];
        [self reloadSectionControllers];
    });
}

#pragma mark - Data Source Configuration

- (void)configureDataSourceIfNeeded {
    if (self.dataSource.tableView) {
        return;
    }

    self.dataSource.rowAnimation = UITableViewRowAnimationNone;

    @weakify(self);

    self.dataSource.cellCreationBlock = (id) ^ (id object, id parentView, NSIndexPath * indexPath){
        @strongify(self);
        id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        return [controller dequeueCellForTableView:parentView atIndexPath:indexPath];
    };

    self.dataSource.cellConfigureBlock = ^(id cell, id object, id parentView, NSIndexPath* indexPath){
        @strongify(self);
        id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        [controller configureCell:cell withObject:object inTableView:parentView atIndexPath:indexPath];
    };

    [self.tableView registerNib:[WMFExploreSectionHeader wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self.tableView registerNib:[WMFExploreSectionFooter wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];

    self.dataSource.tableView = self.tableView;
    // HAX: setup empty state, otherwise we get out-of-bounds due to header/footer queries for non-existent sections
    [self.dataSource reloadData];
    self.tableView.delegate = self;

    self.sectionLoadErrors = [NSMutableDictionary dictionary];
    [self updateSectionSchemaForce:NO];
    [self loadSectionControllers];
}

#pragma mark - Section Controller Creation

- (WMFRelatedSectionController*)relatedSectionControllerForSectionSchemaItem:(WMFExploreSection*)item {
    return [[WMFRelatedSectionController alloc] initWithArticleTitle:item.title blackList:[WMFRelatedSectionBlackList sharedBlackList] dataStore:self.dataStore tabBar:self.navigationController.tabBarController.tabBar];
}

- (WMFNearbySectionController*)nearbySectionControllerForSchemaItem:(WMFExploreSection*)item {
    self.nearbySectionController.delegate = nil;
    self.nearbySectionController.location = item.location;
    return self.nearbySectionController;
}

- (WMFContinueReadingSectionController*)continueReadingSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleTitle:item.title dataStore:self.dataStore];
}

- (WMFRandomSectionController*)randomSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFRandomSectionController alloc] initWithSite:self.searchSite savedPageList:self.savedPages];
}

- (WMFMainPageSectionController*)mainPageSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFMainPageSectionController alloc] initWithSite:self.searchSite savedPageList:self.savedPages];
}

- (WMFPictureOfTheDaySectionController*)picOfTheDaySectionController {
    return [[WMFPictureOfTheDaySectionController alloc] init];
}

- (WMFFeaturedArticleSectionController*)featuredArticleSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFFeaturedArticleSectionController alloc] initWithSite:item.site date:item.dateCreated savedPageList:self.savedPages];
}

#pragma mark - Delayed Fetching

- (void)fetchSectionIfShowing:(id<WMFExploreSectionController, WMFFetchingExploreSectionController>)controller {
    if ([self isDisplayingCellsForSectionController:controller]) {
        DDLogVerbose(@"Fetching section after delay: %@", controller);
        [controller fetchDataIfNeeded];
    } else {
        DDLogInfo(@"Section for controller %@ is no longer visible, skipping fetch.", controller);
    }
}

#pragma mark - Section Update

- (NSString*)lastUpdatedString {
    if (!self.schemaManager.lastUpdatedAt) {
        return MWLocalizedString(@"home-last-update-never-label", nil);
    }

    static NSDateFormatter* formatter;
    if (!formatter) {
        formatter           = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    }

    return [MWLocalizedString(@"home-last-update-label", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[formatter stringFromDate:self.schemaManager.lastUpdatedAt]];
}

- (void)resetRefreshControlWithCompletion:(nullable dispatch_block_t)completion {
    //Don't hide the spinner so quickly - so users can see the change
    dispatchOnMainQueueAfterDelayInSeconds(1.0, ^{
        [CATransaction begin];
        [self.refreshControl endRefreshing];
        [CATransaction setCompletionBlock:^{
            dispatchOnMainQueueAfterDelayInSeconds(0.5, ^{
                if (completion) {
                    completion();
                }
            });
        }];
        [CATransaction commit];
    });
}

- (void)updateSectionSchemaIfNeeded {
    BOOL forceUpdate = self.sectionLoadErrors.count > 0;
    [self updateSectionSchemaForce:forceUpdate];
}

- (void)updateSectionSchemaForce:(BOOL)force {
    [self.refreshControl beginRefreshing];
    self.sectionLoadErrors = [NSMutableDictionary dictionary];
    [self.schemaManager update:force];
}

#pragma mark - Section Management

- (void)reloadSectionControllers {
    [self unloadAllSectionControllers];
    [self loadSectionControllers];
}

- (void)loadSectionControllers {
    [self.schemaManager.sections enumerateObjectsUsingBlock:^(WMFExploreSection* obj, NSUInteger idx, BOOL* stop) {
        switch (obj.type) {
            case WMFExploreSectionTypeHistory:
            case WMFExploreSectionTypeSaved:
                [self loadSectionForSectionController:[self relatedSectionControllerForSectionSchemaItem:obj]];
                break;
            case WMFExploreSectionTypeNearby:
                [self loadSectionForSectionController:[self nearbySectionControllerForSchemaItem:obj]];
                break;
            case WMFExploreSectionTypeContinueReading:
                [self loadSectionForSectionController:[self continueReadingSectionControllerForSchemaItem:obj]];
                break;
            case WMFExploreSectionTypeRandom:
                [self loadSectionForSectionController:[self randomSectionControllerForSchemaItem:obj]];
                break;
            case WMFExploreSectionTypeMainPage:
                [self loadSectionForSectionController:[self mainPageSectionControllerForSchemaItem:obj]];
                break;
            case WMFExploreSectionTypeFeaturedArticle:
                [self loadSectionForSectionController:[self featuredArticleSectionControllerForSchemaItem:obj]];
                break;
            case WMFExploreSectionTypePictureOfTheDay:
                [self loadSectionForSectionController:[self picOfTheDaySectionController]];
                break;
                /*
                   !!!: do not add a default case, it is intentionally omitted so an error/warning is triggered when
                   a new case is added to the enum, enforcing that all sections are handled here.
                 */
        }
    }];
}

- (nullable id<WMFExploreSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    if (index >= [self.dataSource numberOfSections]) {
        return nil;
    }
    SSSection* section = [self.dataSource sectionAtIndex:index];
    return self.sectionControllers[section.sectionIdentifier];
}

- (NSInteger)indexForSectionController:(id<WMFExploreSectionController>)controller {
    return (NSInteger)[self.dataSource indexOfSectionWithIdentifier:[controller sectionIdentifier]];
}

- (void)loadSectionForSectionController:(id<WMFExploreSectionController>)controller {
    if (!controller) {
        return;
    }
    self.sectionControllers[controller.sectionIdentifier] = controller;

    [controller registerCellsInTableView:self.tableView];

    SSSection* section = [SSSection sectionWithItems:[controller items]];
    section.sectionIdentifier = controller.sectionIdentifier;
    controller.delegate       = self;

    [self.dataSource appendSection:section];

    if ([self isDisplayingCellsForSectionController:controller]) {
        [self resetRefreshControlWithCompletion:NULL];
        if ([controller conformsToProtocol:@protocol(WMFFetchingExploreSectionController)]) {
            [(NSObject < WMFFetchingExploreSectionController > *)controller performSelector:@selector(fetchDataIfNeeded) withObject:nil afterDelay:0.25];
        }
    }
}

- (void)reloadSectionForSectionController:(id<WMFExploreSectionController>)controller {
    if (!controller) {
        return;
    }

    NSInteger sectionIndex = [self indexForSectionController:controller];
    NSAssert(sectionIndex != NSNotFound, @"Unknown section calling delegate");
    if (sectionIndex == NSNotFound) {
        return;
    }

    SSSection* section = [self.dataSource sectionAtIndex:sectionIndex];

    [section.items setArray:controller.items];

    [self.tableView wmf_performUpdates:^{
        /*
           HAX: must reload entire table, otherwise UITableView crashes due to inserting nil in an internal array

           This is true even when we tried wrapping in (nested) begin/endUpdate calls and asynchronous queueing of updates.
         */
        [self.tableView reloadData];
    } withoutMovingCellAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
}

- (void)unloadSectionForSectionController:(id<WMFExploreSectionController>)controller {
    if (!controller) {
        return;
    }

    controller.delegate = nil;

    NSUInteger index = [self indexForSectionController:controller];

    if (controller.sectionIdentifier) {
        [self.sectionControllers removeObjectForKey:controller.sectionIdentifier];
    }

    if (index == NSNotFound) {
        return;
    }

    [self.dataSource removeSectionAtIndex:index];
}

- (void)unloadAllSectionControllers {
    [self.sectionControllers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id < WMFExploreSectionController > _Nonnull controller, BOOL* _Nonnull stop) {
        controller.delegate = nil;
        [self.sectionControllers removeObjectForKey:controller.sectionIdentifier];
    }];
    [self.sectionLoadErrors removeAllObjects];
    [self.dataSource removeAllSections];
}

- (void)didTapFooterInSection:(NSUInteger)section {
    id<WMFExploreSectionController> controllerForSection = [self sectionControllerForSectionAtIndex:section];
    NSParameterAssert(controllerForSection);
    if (!controllerForSection) {
        DDLogError(@"Unexpected footer tap for missing section %lu.", section);
        return;
    }
    if (![controllerForSection respondsToSelector:@selector(moreViewController)]) {
        return;
    }
    id<WMFArticleExploreSectionController> articleSectionController = (id<WMFArticleExploreSectionController>)controllerForSection;

    UIViewController* moreVC = [articleSectionController moreViewController];
    [[PiwikTracker sharedInstance] wmf_logActionOpenMoreForHomeSection:articleSectionController];
    [self.navigationController pushViewController:moreVC animated:YES];
}

- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFExploreSection* homeSection = self.schemaManager.sections[section];
    switch (homeSection.type) {
        case WMFExploreSectionTypeContinueReading:
        case WMFExploreSectionTypeMainPage:
        case WMFExploreSectionTypeFeaturedArticle:
        case WMFExploreSectionTypePictureOfTheDay:
        case WMFExploreSectionTypeRandom:
            [self selectFirstRowInSection:section];
            break;
        case WMFExploreSectionTypeNearby:
            [self didTapFooterInSection:section];
            break;
        case WMFExploreSectionTypeSaved:
        case WMFExploreSectionTypeHistory: {
            WMFRelatedSectionController* controller = (WMFRelatedSectionController*)[self sectionControllerForSectionAtIndex:section];
            NSParameterAssert(controller);
            [self wmf_pushArticleViewControllerWithTitle:controller.title
                                         discoveryMethod:MWKHistoryDiscoveryMethodLink
                                               dataStore:self.dataStore];
            break;
        }
    }
}

- (void)selectFirstRowInSection:(NSUInteger)section {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    return [controller estimatedRowHeight];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (nullable UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section; {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    if (!controller) {
        return nil;
    }

    WMFExploreSectionHeader* header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    header.icon.image     = [[controller headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.icon.tintColor = [UIColor wmf_homeSectionHeaderTextColor];
    NSMutableAttributedString* title = [[controller headerText] mutableCopy];
    [title addAttribute:NSFontAttributeName value:[UIFont wmf_homeSectionHeaderFont] range:NSMakeRange(0, title.length)];
    header.titleView.attributedText = title;
    header.titleView.tintColor      = [UIColor wmf_homeSectionHeaderLinkTextColor];

    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:section];
    };

    if ([controller respondsToSelector:@selector(headerButtonIcon)]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[controller headerButtonIcon] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        [header.rightButton bk_addEventHandler:^(id sender) {
            [controller performHeaderButtonAction];
        } forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    }

    return header;
}

- (nullable UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    if (!controller) {
        return nil;
    }
    WMFExploreSectionFooter* footer = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFExploreSectionFooter wmf_nibName]];
    if ([controller respondsToSelector:@selector(footerText)]) {
        footer.visibleBackgroundView.alpha = 1.0;
        footer.moreLabel.text              = controller.footerText;
        footer.moreLabel.textColor         = [UIColor wmf_homeSectionFooterTextColor];
        @weakify(self);
        footer.whenTapped = ^{
            @strongify(self);
            [self didTapFooterInSection:section];
        };
    } else {
        footer.visibleBackgroundView.alpha = 0.0;
        footer.moreLabel.text              = nil;
        footer.whenTapped                  = NULL;
    }
    return footer;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller isKindOfClass:[WMFNearbySectionController class]]) {
        [self.nearbySectionController startMonitoringLocation];
    }

    if ([controller conformsToProtocol:@protocol(WMFFetchingExploreSectionController)]
        && self.sectionLoadErrors[controller.sectionIdentifier] == nil) {
        // don't automatically re-fetch a section if it previously failed. ask user to refresh manually
        [self performSelector:@selector(fetchSectionIfShowing:) withObject:controller afterDelay:0.25 inModes:@[NSRunLoopCommonModes]];
    }

    if ([controller conformsToProtocol:@protocol(WMFArticleExploreSectionController)]
        && (![controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]
            || [controller shouldSelectItemAtIndex:indexPath.item])) {
        MWKTitle* title = [(id < WMFArticleExploreSectionController >)controller titleForItemAtIndex:indexPath.row];
        if (title) {
            [[PiwikTracker sharedInstance] wmf_logActionScrollToTitle:title inHomeSection:controller];
        }
    }
}

- (void)tableView:(UITableView*)tableView didEndDisplayingCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    NSArray<NSIndexPath*>* visibleIndexPathsInSection = [tableView.indexPathsForVisibleRows bk_select:^BOOL (NSIndexPath* i) {
        return i.section == indexPath.section;
    }];
    if (visibleIndexPathsInSection.count == 0) {
        id controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        if ([controller conformsToProtocol:@protocol(WMFFetchingExploreSectionController)]) {
            DDLogInfo(@"Cancelling fetch for scrolled-away section: %@", controller);
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchSectionIfShowing:) object:controller];
        }
    }

    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller isKindOfClass:[WMFNearbySectionController class]]) {
        __block BOOL isShowingNearbyCells = NO;
        [[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(NSIndexPath* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
            if (indexPath.section == obj.section) {
                isShowingNearbyCells = YES;
                *stop = YES;
            }
        }];

        if (!isShowingNearbyCells) {
            [self.nearbySectionController stopMonitoringLocation];
        }
    }
}

- (BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]) {
        return [controller shouldSelectItemAtIndex:indexPath.item];
    }
    return YES;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]
        && ![controller shouldSelectItemAtIndex:indexPath.item]) {
        return;
    }
    if ([controller conformsToProtocol:@protocol(WMFArticleExploreSectionController)]) {
        MWKTitle* title = [(id < WMFArticleExploreSectionController >)controller titleForItemAtIndex:indexPath.row];
        if (title) {
            [[PiwikTracker sharedInstance] wmf_logActionOpenTitle:title inHomeSection:controller];
            MWKHistoryDiscoveryMethod discoveryMethod = [self discoveryMethodForSectionController:controller];
            [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:discoveryMethod dataStore:self.dataStore];
        }
    } else if ([controller conformsToProtocol:@protocol(WMFGenericExploreSectionController)]) {
        UIViewController* detailViewController =
            [(id < WMFGenericExploreSectionController >)controller exploreDetailViewControllerForItemAtIndex:indexPath.item];
        [self presentViewController:detailViewController animated:YES completion:nil];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethodForSectionController:(id<WMFExploreSectionController>)sectionController {
    if ([sectionController respondsToSelector:@selector(discoveryMethod)]) {
        return [sectionController discoveryMethod];
    } else {
        return MWKHistoryDiscoveryMethodSearch;
    }
}

#pragma mark - WMFExploreSectionSchemaDelegate

- (void)sectionSchemaDidUpdateSections:(WMFExploreSectionSchema*)schema {
    [self wmf_hideEmptyView];
    [self reloadSectionControllers];
}

- (void)sectionSchema:(WMFExploreSectionSchema*)schema didRemoveSection:(WMFExploreSection*)section atIndex:(NSUInteger)index {
    [self.dataSource.sections removeObjectAtIndex:index];
    [self.tableView reloadData];
}

#pragma mark - WMFHomeSectionControllerDelegate

- (void)controller:(id<WMFExploreSectionController>)controller didSetItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Reloading section %ld: %@", section, controller);
    [self reloadSectionForSectionController:controller];
}

- (void)controller:(id<WMFExploreSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Appending items in section %ld: %@", section, controller);
    [self.dataSource appendItems:items toSection:section];
}

- (void)controller:(id<WMFExploreSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes {
    NSInteger sectionIndex = [self indexForSectionController:controller];
    NSAssert(sectionIndex != NSNotFound, @"Unknown section calling delegate");
    if (sectionIndex == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Updating items in section %ld: %@", sectionIndex, controller);
    [self.tableView wmf_performUpdates:^{
        // see comment in reloadSectionController
        [self.tableView reloadData];
    } withoutMovingCellAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
}

- (void)controller:(id<WMFExploreSectionController>)controller didFailToUpdateWithError:(NSError*)error {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Encountered %@ in section %ld: %@", error, section, controller);
    self.sectionLoadErrors[controller.sectionIdentifier] = error;
    if ([error wmf_isNetworkConnectionError]) {
        [self showOfflineEmptyViewAndReloadWhenReachable];
    }
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
}

#pragma mark - WMFSearchPresentationDelegate

- (MWKDataStore*)searchDataStore {
    return self.dataStore;
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    [self dismissViewControllerAnimated:YES completion:^{
        [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:discoveryMethod dataStore:self.dataStore];
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
    NSIndexPath* previewIndexPath                     = [self.tableView indexPathForRowAtPoint:location];
    id<WMFExploreSectionController> sectionController = [self sectionControllerForSectionAtIndex:previewIndexPath.section];
    if (!sectionController) {
        return nil;
    }

    previewingContext.sourceRect = [self.tableView cellForRowAtIndexPath:previewIndexPath].frame;

    if ([sectionController conformsToProtocol:@protocol(WMFArticleExploreSectionController)]) {
        MWKTitle* title =
            [(id < WMFArticleExploreSectionController >)sectionController titleForItemAtIndex:previewIndexPath.item];
        if (title) {
            self.previewingTitle          = title;
            self.sectionOfPreviewingTitle = sectionController;
            [[PiwikTracker sharedInstance] wmf_logActionPreviewForTitle:title fromSource:self];
            return [[WMFArticleContainerViewController alloc]
                    initWithArticleTitle:title
                               dataStore:[self dataStore]
                         discoveryMethod:[self discoveryMethodForSectionController:sectionController]];
        }
    } else if ([sectionController conformsToProtocol:@protocol(WMFGenericExploreSectionController)]) {
        return [(id < WMFGenericExploreSectionController >)sectionController exploreDetailViewControllerForItemAtIndex:previewIndexPath.item];
    }

    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[WMFArticleContainerViewController class]]) {
        [[PiwikTracker sharedInstance] wmf_logActionOpenTitle:self.previewingTitle inHomeSection:self.sectionOfPreviewingTitle];
        [[PiwikTracker sharedInstance] wmf_logActionPreviewCommittedForTitle:self.previewingTitle fromSource:self];
        self.previewingTitle          = nil;
        self.sectionOfPreviewingTitle = nil;
        [self wmf_pushArticleViewController:(WMFArticleContainerViewController*)viewControllerToCommit];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSString*)analyticsName {
    return @"Home";
}

@end

NS_ASSUME_NONNULL_END
