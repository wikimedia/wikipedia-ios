#import "WMFHomeViewController.h"
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
#import "WMFHomeSectionSchema.h"
#import "WMFHomeSection.h"
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
#import "WMFHomeSectionHeader.h"
#import "WMFHomeSectionFooter.h"
#import "UITableView+WMFLockedUpdates.h"

// Child View Controllers
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFArticleContainerViewController.h"
#import "WMFSettingsViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFTitleListDataSource.h"
#import "WMFArticleListTableViewController.h"

// Controllers
#import "WMFLocationManager.h"
#import "UITabBarController+WMFExtensions.h"
#import "UIViewController+WMFSearchButton.h"
#import "UIViewController+WMFArticlePresentation.h"

static DDLogLevel const WMFHomeVCLogLevel = DDLogLevelVerbose;
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFHomeVCLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeViewController ()
<WMFHomeSectionSchemaDelegate,
 WMFHomeSectionControllerDelegate,
 WMFSearchPresentationDelegate,
 UIViewControllerPreviewingDelegate,
 WMFAnalyticsLogging>

@property (nonatomic, strong, null_resettable) WMFHomeSectionSchema* schemaManager;

@property (nonatomic, strong, null_resettable) WMFNearbySectionController* nearbySectionController;
@property (nonatomic, strong) NSMutableDictionary* sectionControllers;

@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong) NSMutableDictionary* sectionLoadErrors;

@property (nonatomic, strong, nullable) MWKTitle* previewingTitle;
@property (nonatomic, strong, nullable) id<WMFHomeSectionController> sectionOfPreviewingTitle;

@end

@implementation WMFHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.titleView          = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"W"]];
        self.navigationItem.leftBarButtonItem  = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItemWithDelegate:self];
    }
    return self;
}

#pragma mark - Accessors

- (UIBarButtonItem*)settingsBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    if ([_searchSite isEqualToSite:searchSite]) {
        return;
    }
    _searchSite = searchSite;

    self.schemaManager           = nil;
    self.nearbySectionController = nil;

    if ([self.sectionControllers count] > 0) {
        [self updateSectionSchemaIfNeeded];
        [self reloadSectionControllers];
    }
}

- (WMFHomeSectionSchema*)schemaManager {
    if (!_schemaManager) {
        _schemaManager = [WMFHomeSectionSchema schemaWithSite:self.searchSite
                                                   savedPages:self.savedPages
                                                      history:self.recentPages];
        _schemaManager.delegate = self;
    }
    return _schemaManager;
}

- (WMFNearbySectionController*)nearbySectionController {
    if (!_nearbySectionController) {
        _nearbySectionController = [[WMFNearbySectionController alloc] initWithSite:self.searchSite
                                                                      savedPageList:self.savedPages
                                                                    locationManager:self.locationManager];
    }
    return _nearbySectionController;
}

- (WMFLocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [[WMFLocationManager alloc] init];
    }
    return _locationManager;
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

- (BOOL)isDisplayingCellsForSectionController:(id<WMFHomeSectionController>)controller {
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

    self.title = MWLocalizedString(@"home-title", nil);

    self.tableView.dataSource                   = nil;
    self.tableView.delegate                     = nil;
    self.tableView.estimatedRowHeight           = 345.0;
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 78.0;
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
        [self.locationManager startMonitoringLocation];
    }

    if (self.previewingTitle) {
        [[PiwikTracker sharedInstance] wmf_logActionPreviewDismissedForTitle:self.previewingTitle fromSource:self];
        self.previewingTitle = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // stop location manager from updating.
    [self.locationManager stopMonitoringLocation];
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
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        return [controller dequeueCellForTableView:parentView atIndexPath:indexPath];
    };

    self.dataSource.cellConfigureBlock = ^(id cell, id object, id parentView, NSIndexPath* indexPath){
        @strongify(self);
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        [controller configureCell:cell withObject:object inTableView:parentView atIndexPath:indexPath];
    };

    [self.tableView registerNib:[WMFHomeSectionHeader wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFHomeSectionHeader wmf_nibName]];

    [self.tableView registerNib:[WMFHomeSectionFooter wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFHomeSectionFooter wmf_nibName]];

    self.dataSource.tableView = self.tableView;
    // HAX: setup empty state, otherwise we get out-of-bounds due to header/footer queries for non-existent sections
    [self.dataSource reloadData];
    self.tableView.delegate = self;

    self.sectionLoadErrors = [NSMutableDictionary dictionary];
    [self loadSectionControllers];
}

#pragma mark - Section Controller Creation

- (WMFRelatedSectionController*)relatedSectionControllerForSectionSchemaItem:(WMFHomeSection*)item {
    return [[WMFRelatedSectionController alloc] initWithArticleTitle:item.title savedPageList:self.savedPages];
}

- (WMFContinueReadingSectionController*)continueReadingSectionControllerForSchemaItem:(WMFHomeSection*)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleTitle:item.title dataStore:self.dataStore];
}

- (WMFRandomSectionController*)randomSectionControllerForSchemaItem:(WMFHomeSection*)item {
    return [[WMFRandomSectionController alloc] initWithSite:self.searchSite savedPageList:self.savedPages];
}

- (WMFMainPageSectionController*)mainPageSectionControllerForSchemaItem:(WMFHomeSection*)item {
    return [[WMFMainPageSectionController alloc] initWithSite:self.searchSite savedPageList:self.savedPages];
}

- (WMFPictureOfTheDaySectionController*)picOfTheDaySectionController {
    return [[WMFPictureOfTheDaySectionController alloc] init];
}

- (WMFFeaturedArticleSectionController*)featuredArticleSectionControllerForSchemaItem:(WMFHomeSection*)item {
    return [[WMFFeaturedArticleSectionController alloc] initWithSite:item.site date:item.dateCreated savedPageList:self.savedPages];
}

#pragma mark - Section Management

- (void)updateSectionSchemaIfNeeded {
    [self wmf_hideEmptyView];
    BOOL forceUpdate = self.sectionLoadErrors.count > 0;
    self.sectionLoadErrors = [NSMutableDictionary dictionary];
    [self.schemaManager update:forceUpdate];
}

- (void)reloadSectionControllers {
    [self unloadAllSectionControllers];
    [self loadSectionControllers];
}

- (void)loadSectionControllers {
    [self.tableView beginUpdates];

    [self.schemaManager.sections enumerateObjectsUsingBlock:^(WMFHomeSection* obj, NSUInteger idx, BOOL* stop) {
        switch (obj.type) {
            case WMFHomeSectionTypeHistory:
            case WMFHomeSectionTypeSaved:
                [self loadSectionForSectionController:[self relatedSectionControllerForSectionSchemaItem:obj]];
                break;
            case WMFHomeSectionTypeNearby:
                [self loadSectionForSectionController:self.nearbySectionController];
                break;
            case WMFHomeSectionTypeContinueReading:
                [self loadSectionForSectionController:[self continueReadingSectionControllerForSchemaItem:obj]];
                break;
            case WMFHomeSectionTypeRandom:
                [self loadSectionForSectionController:[self randomSectionControllerForSchemaItem:obj]];
                break;
            case WMFHomeSectionTypeMainPage:
                [self loadSectionForSectionController:[self mainPageSectionControllerForSchemaItem:obj]];
                break;
            case WMFHomeSectionTypeFeaturedArticle:
                [self loadSectionForSectionController:[self featuredArticleSectionControllerForSchemaItem:obj]];
                break;
            case WMFHomeSectionTypePictureOfTheDay:
                [self loadSectionForSectionController:[self picOfTheDaySectionController]];
                break;
                /*
                   !!!: do not add a default case, it is intentionally omitted so an error/warning is triggered when
                   a new case is added to the enum, enforcing that all sections are handled here.
                 */
        }
    }];

    [self.tableView endUpdates];
}

- (nullable id<WMFHomeSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    if (index >= [self.dataSource numberOfSections]) {
        return nil;
    }
    SSSection* section = [self.dataSource sectionAtIndex:index];
    return self.sectionControllers[section.sectionIdentifier];
}

- (NSInteger)indexForSectionController:(id<WMFHomeSectionController>)controller {
    return (NSInteger)[self.dataSource indexOfSectionWithIdentifier:[controller sectionIdentifier]];
}

- (void)loadSectionForSectionController:(id<WMFHomeSectionController>)controller {
    if (!controller) {
        return;
    }
    self.sectionControllers[controller.sectionIdentifier] = controller;

    [controller registerCellsInTableView:self.tableView];

    SSSection* section = [SSSection sectionWithItems:[controller items]];
    section.sectionIdentifier = controller.sectionIdentifier;
    controller.delegate       = self;

    [self.dataSource appendSection:section];

    if ([controller conformsToProtocol:@protocol(WMFFetchingHomeSectionController)]
        && [self isDisplayingCellsForSectionController:controller]) {
        [(id < WMFFetchingHomeSectionController >)controller fetchDataIfNeeded];
    }
}

- (void)reloadSectionForSectionController:(id<WMFHomeSectionController>)controller {
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

- (void)unloadSectionForSectionController:(id<WMFHomeSectionController>)controller {
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
    [self.sectionControllers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id < WMFHomeSectionController > _Nonnull controller, BOOL* _Nonnull stop) {
        controller.delegate = nil;
        [self.sectionControllers removeObjectForKey:controller.sectionIdentifier];
    }];
    [self.sectionLoadErrors removeAllObjects];
    [self.dataSource removeAllSections];
}

- (void)didTapFooterInSection:(NSUInteger)section {
    id<WMFHomeSectionController> controllerForSection = [self sectionControllerForSectionAtIndex:section];
    NSParameterAssert(controllerForSection);
    if (!controllerForSection) {
        DDLogError(@"Unexpected footer tap for missing section %lu.", section);
        return;
    }
    if (![controllerForSection respondsToSelector:@selector(extendedListDataSource)]) {
        return;
    }
    id<WMFArticleHomeSectionController> articleSectionController = (id<WMFArticleHomeSectionController>)controllerForSection;
    WMFArticleListTableViewController* extendedList              = [[WMFArticleListTableViewController alloc] init];
    extendedList.dataStore  = self.dataStore;
    extendedList.dataSource = [articleSectionController extendedListDataSource];
    [[PiwikTracker sharedInstance] wmf_logActionOpenMoreForHomeSection:articleSectionController];
    [self.navigationController pushViewController:extendedList animated:YES];
}

- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFHomeSection* homeSection = self.schemaManager.sections[section];
    switch (homeSection.type) {
        case WMFHomeSectionTypeContinueReading:
        case WMFHomeSectionTypeMainPage:
        case WMFHomeSectionTypeFeaturedArticle:
        case WMFHomeSectionTypePictureOfTheDay:
        case WMFHomeSectionTypeRandom:
            [self selectFirstRowInSection:section];
            break;
        case WMFHomeSectionTypeNearby:
            [self didTapFooterInSection:section];
            break;
        case WMFHomeSectionTypeSaved:
        case WMFHomeSectionTypeHistory: {
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

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (nullable UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section; {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    if (!controller) {
        return nil;
    }

    WMFHomeSectionHeader* header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFHomeSectionHeader wmf_nibName]];

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
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    if (!controller) {
        return nil;
    }
    WMFHomeSectionFooter* footer = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFHomeSectionFooter wmf_nibName]];
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
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller conformsToProtocol:@protocol(WMFFetchingHomeSectionController)]
        && self.sectionLoadErrors[controller.sectionIdentifier] == nil) {
        // don't automatically re-fetch a section if it previously failed. ask user to refresh manually
        [(id < WMFFetchingHomeSectionController >)controller fetchDataIfNeeded];
    }

    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]
        && ![controller shouldSelectItemAtIndex:indexPath.item]) {
        return;
    }
    if ([controller conformsToProtocol:@protocol(WMFArticleHomeSectionController)]) {
        MWKTitle* title = [(id < WMFArticleHomeSectionController >)controller titleForItemAtIndex:indexPath.row];
        if (title) {
            [[PiwikTracker sharedInstance] wmf_logActionScrollToTitle:title inHomeSection:controller];
        }
    }
}

- (BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]) {
        return [controller shouldSelectItemAtIndex:indexPath.item];
    }
    return YES;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]
        && ![controller shouldSelectItemAtIndex:indexPath.item]) {
        return;
    }
    if ([controller conformsToProtocol:@protocol(WMFArticleHomeSectionController)]) {
        MWKTitle* title = [(id < WMFArticleHomeSectionController >)controller titleForItemAtIndex:indexPath.row];
        if (title) {
            [[PiwikTracker sharedInstance] wmf_logActionOpenTitle:title inHomeSection:controller];
            MWKHistoryDiscoveryMethod discoveryMethod = [self discoveryMethodForSectionController:controller];
            [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:discoveryMethod dataStore:self.dataStore];
        }
    } else if ([controller conformsToProtocol:@protocol(WMFGenericHomeSectionController)]) {
        UIViewController* detailViewController =
            [(id < WMFGenericHomeSectionController >)controller homeDetailViewControllerForItemAtIndex:indexPath.item];
        [self presentViewController:detailViewController animated:YES completion:nil];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethodForSectionController:(id<WMFHomeSectionController>)sectionController {
    if ([sectionController respondsToSelector:@selector(discoveryMethod)]) {
        return [sectionController discoveryMethod];
    } else {
        return MWKHistoryDiscoveryMethodSearch;
    }
}

#pragma mark - WMFHomeSectionSchemaDelegate

- (void)sectionSchemaDidUpdateSections:(WMFHomeSectionSchema*)schema {
    [self reloadSectionControllers];
}

#pragma mark - WMFHomeSectionControllerDelegate

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Reloading section %ld: %@", section, controller);
    [self reloadSectionForSectionController:controller];
}

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    DDLogVerbose(@"Appending items in section %ld: %@", section, controller);
    [self.dataSource appendItems:items toSection:section];
}

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes {
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

- (void)controller:(id<WMFHomeSectionController>)controller didFailToUpdateWithError:(NSError*)error {
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
    NSIndexPath* previewIndexPath                  = [self.tableView indexPathForRowAtPoint:location];
    id<WMFHomeSectionController> sectionController = [self sectionControllerForSectionAtIndex:previewIndexPath.section];
    if (!sectionController) {
        return nil;
    }

    previewingContext.sourceRect = [self.tableView cellForRowAtIndexPath:previewIndexPath].frame;

    if ([sectionController conformsToProtocol:@protocol(WMFArticleHomeSectionController)]) {
        MWKTitle* title =
            [(id < WMFArticleHomeSectionController >)sectionController titleForItemAtIndex:previewIndexPath.item];
        if (title) {
            self.previewingTitle          = title;
            self.sectionOfPreviewingTitle = sectionController;
            [[PiwikTracker sharedInstance] wmf_logActionPreviewForTitle:title fromSource:self];
            return [[WMFArticleContainerViewController alloc]
                    initWithArticleTitle:title
                               dataStore:[self dataStore]
                         discoveryMethod:[self discoveryMethodForSectionController:sectionController]];
        }
    } else if ([sectionController conformsToProtocol:@protocol(WMFGenericHomeSectionController)]) {
        return [(id < WMFGenericHomeSectionController >)sectionController homeDetailViewControllerForItemAtIndex:previewIndexPath.item];
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
