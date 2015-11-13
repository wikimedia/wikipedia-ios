#import "WMFHomeViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
@import SSDataSources;
@import Tweaks;
@import BlocksKit;

// Sections
#import "WMFMainPageSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRelatedSectionController.h"
#import "WMFContinueReadingSectionController.h"
#import "WMFRandomSectionController.h"
#import "SSSectionedDataSource+WMFSectionConvenience.h"
#import "WMFHomeSectionSchema.h"
#import "WMFHomeSection.h"

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
#import "UIView+WMFDefaultNib.h"
#import "WMFHomeSectionHeader.h"
#import "WMFHomeSectionFooter.h"

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

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeViewController ()
<WMFHomeSectionSchemaDelegate,
 WMFHomeSectionControllerDelegate,
 UITextViewDelegate,
 WMFSearchPresentationDelegate,
 UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) WMFHomeSectionSchema* schemaManager;

@property (nonatomic, strong, null_resettable) WMFNearbySectionController* nearbySectionController;
@property (nonatomic, strong) NSMutableDictionary* sectionControllers;

@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, strong) NSOperationQueue* collectionViewUpdateQueue;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

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
    _searchSite                  = searchSite;
    self.nearbySectionController = nil;

    if ([self.sectionControllers count] > 0) {
        [self reloadSectionsOnOperationQueue];
    }
}

- (WMFHomeSectionSchema*)schemaManager {
    if (!_schemaManager) {
        _schemaManager          = [WMFHomeSectionSchema schemaWithSavedPages:self.savedPages history:self.recentPages];
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

#pragma mark - Actions

- (void)didTapSettingsButton:(UIBarButtonItem*)sender {
    UINavigationController* settingsContainer =
        [[UINavigationController alloc] initWithRootViewController:
         [WMFSettingsViewController wmf_initialViewControllerFromClassStoryboard]];
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
}

- (void)didTapSectionHeaderLink:(NSURL*)url {
    [self wmf_pushArticleViewControllerWithTitle:[[MWKTitle alloc] initWithURL:url]
                                 discoveryMethod:MWKHistoryDiscoveryMethodLink
                                       dataStore:self.dataStore];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = MWLocalizedString(@"home-title", nil);

    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    queue.qualityOfService            = NSQualityOfServiceUserInteractive;
    self.collectionViewUpdateQueue    = queue;

    self.tableView.dataSource                   = nil;
    self.tableView.delegate                     = nil;
    self.tableView.estimatedRowHeight           = 380.0;
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 78.0;
    self.tableView.sectionFooterHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 78.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tweaksDidChangeWithNotification:) name:FBTweakShakeViewControllerDidDismissNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.searchSite);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    [super viewDidAppear:animated];
    [self configureDataSource];
    [self.locationManager startMonitoringLocation];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.locationManager stopMonitoringLocation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:NULL];
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

    //never loaded, do not reload
    if ([self.dataSource numberOfSections] == 0) {
        return;
    }

    [self.schemaManager update];
}

#pragma mark - Tweaks

- (void)tweaksDidChangeWithNotification:(NSNotification*)note {
    [self.schemaManager update];
}

#pragma mark - Data Source Configuration

- (void)configureDataSource {
    if ([self.dataSource numberOfSections] > 0) {
        return;
    }

    self.dataSource.rowAnimation = UITableViewRowAnimationFade;

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

    [self.tableView registerNib:[WMFHomeSectionHeader wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFHomeSectionHeader wmf_nibName]];
    [self.tableView registerNib:[WMFHomeSectionFooter wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFHomeSectionFooter wmf_nibName]];

    self.dataSource.tableView = self.tableView;
    self.tableView.delegate   = self;
    [self reloadSectionsOnOperationQueue];
    [self updateSectionsOnOperationQueue];
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
    return [[WMFMainPageSectionController alloc] initWithSite:self.searchSite];
}

#pragma mark - Section Management

- (void)updateSectionsOnOperationQueue {
    @weakify(self);
    [self.collectionViewUpdateQueue wmf_addOperationWithAsyncBlock:^(WMFAsyncBlockOperation* _Nonnull operation) {
        dispatchOnMainQueue(^{
            @strongify(self);
            [self.schemaManager update];
            [operation finish];
        });
    }];
}

- (void)reloadSectionsOnOperationQueue {
    @weakify(self);
    [self.collectionViewUpdateQueue wmf_addOperationWithAsyncBlock:^(WMFAsyncBlockOperation* _Nonnull operation) {
        dispatchOnMainQueue(^{
            @strongify(self);
            [self unloadAllSections];
            [operation finish];
        });
    }];
    [self.collectionViewUpdateQueue wmf_addOperationWithAsyncBlock:^(WMFAsyncBlockOperation* _Nonnull operation) {
        dispatchOnMainQueue(^{
            @strongify(self);
            [self loadSections];
            [operation finish];
        });
    }];
}

- (void)loadSections {
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
            default:
                break;
        }
    }];
    [self.tableView endUpdates];
}

- (id<WMFHomeSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
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

    [self.dataSource appendSection:section];
    controller.delegate = self;
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

- (void)unloadAllSections {
    [self.sectionControllers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id < WMFHomeSectionController > _Nonnull controller, BOOL* _Nonnull stop) {
        controller.delegate = nil;
        [self.sectionControllers removeObjectForKey:controller.sectionIdentifier];
    }];
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
    WMFArticleListTableViewController* extendedList = [[WMFArticleListTableViewController alloc] init];
    extendedList.dataStore  = self.dataStore;
    extendedList.dataSource = [controllerForSection extendedListDataSource];
    [self.navigationController pushViewController:extendedList animated:YES];
}

#pragma mark - UITableViewDelegate

- (nullable UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section; {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    WMFHomeSectionHeader* header            = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFHomeSectionHeader wmf_nibName]];
    header.icon.image     = [[controller headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.icon.tintColor = [UIColor wmf_homeSectionHeaderTextColor];
    NSMutableAttributedString* title = [[controller headerText] mutableCopy];
    [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0] range:NSMakeRange(0, title.length)];
    [title addAttribute:NSForegroundColorAttributeName value:[UIColor wmf_homeSectionHeaderTextColor] range:NSMakeRange(0, title.length)];
    header.titleView.attributedText = title;
    header.titleView.tintColor      = [UIColor wmf_homeSectionHeaderLinkTextColor];
    header.titleView.delegate       = self;

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
    WMFHomeSectionFooter* footer            = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFHomeSectionFooter wmf_nibName]];
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

- (BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]) {
        return [controller shouldSelectItemAtIndex:indexPath.item];
    }
    return YES;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    MWKTitle* title                         = [controller titleForItemAtIndex:indexPath.row];
    if (title) {
        MWKHistoryDiscoveryMethod discoveryMethod = [self discoveryMethodForSectionController:controller];
        [self wmf_pushArticleViewControllerWithTitle:title discoveryMethod:discoveryMethod dataStore:self.dataStore];
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
    [self reloadSectionsOnOperationQueue];
}

#pragma mark - WMFHomeSectionControllerDelegate

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    [self.tableView beginUpdates];
    [self.dataSource setItems:items inSection:section];
    [self.tableView endUpdates];
}

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    [self.tableView beginUpdates];
    [self.dataSource appendItems:items toSection:section];
    [self.tableView endUpdates];
}

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    [self.tableView beginUpdates];
    [self.dataSource reloadCellsAtIndexes:indexes inSection:section];
    [self.tableView endUpdates];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)url inRange:(NSRange)characterRange {
    [self didTapSectionHeaderLink:url];
    return NO;
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

    return [[WMFArticleContainerViewController alloc] initWithArticleTitle:[sectionController titleForItemAtIndex:previewIndexPath.item]
                                                                 dataStore:[self dataStore]
                                                           discoveryMethod:[self discoveryMethodForSectionController:sectionController]];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(WMFArticleContainerViewController*)viewControllerToCommit {
    [self wmf_pushArticleViewController:viewControllerToCommit];
}

@end

NS_ASSUME_NONNULL_END
