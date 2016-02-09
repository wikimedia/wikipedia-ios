#import "WMFExploreViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <BlocksKit/BlocksKit+UIKit.h>
@import Tweaks;

#import "PiwikTracker+WMFExtensions.h"
#import <PromiseKit/SCNetworkReachability+AnyPromise.h>

// Sections
#import "WMFExploreSectionSchema.h"
#import "WMFExploreSection.h"
#import "WMFExploreSectionControllerCache.h"
#import "WMFRelatedSectionBlackList.h"

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
#import "WMFArticleBrowserViewController.h"
#import "WMFSettingsViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "WMFTitleListDataSource.h"
#import "WMFArticleListTableViewController.h"
#import "WMFRelatedSectionController.h"
#import "UIViewController+WMFSearch.h"

// Controllers
#import "WMFRelatedSectionBlackList.h"

static DDLogLevel const WMFExploreVCLogLevel = DDLogLevelOff;
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFExploreVCLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController ()
<WMFExploreSectionSchemaDelegate,
 UIViewControllerPreviewingDelegate,
 WMFAnalyticsLogging>

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

@property (nonatomic, strong, nullable) WMFExploreSectionSchema* schemaManager;

@property (nonatomic, strong) WMFExploreSectionControllerCache* sectionControllerCache;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, assign) BOOL isPreviewing;
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
        self.navigationItem.rightBarButtonItem               = [self wmf_searchBarButtonItem];
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

    self.schemaManager = nil;
    [self createSectionSchemaIfNeeded];
}

- (WMFExploreSectionControllerCache*)sectionControllerCache {
    NSParameterAssert(self.searchSite);
    NSParameterAssert(self.dataStore);
    if (!_sectionControllerCache) {
        _sectionControllerCache = [[WMFExploreSectionControllerCache alloc] initWithSite:self.searchSite dataStore:self.dataStore];
    }
    return _sectionControllerCache;
}

#pragma mark - Visibility

- (BOOL)isDisplayingCellsForSectionController:(id<WMFExploreSectionController>)controller {
    NSInteger sectionIndex = [self indexForSectionController:controller];
    if (sectionIndex == NSNotFound) {
        return NO;
    }
    return [self.tableView.indexPathsForVisibleRows bk_any:^BOOL (NSIndexPath* indexPath) {
        return indexPath.section == sectionIndex;
    }];
}

- (BOOL)rowAtIndexPathIsOnlyRowVisibleInSection:(NSIndexPath*)indexPath {
    NSArray<NSIndexPath*>* visibleIndexPathsInSection = [self.tableView.indexPathsForVisibleRows bk_select:^BOOL (NSIndexPath* i) {
        return i.section == indexPath.section;
    }];

    if ([visibleIndexPathsInSection count] == 1 && [[visibleIndexPathsInSection firstObject] isEqual:indexPath]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSArray*)visibleSectionControllers {
    NSIndexSet* visibleSectionIndexes = [[self.tableView indexPathsForVisibleRows] bk_reduce:[NSMutableIndexSet indexSet] withBlock:^id (NSMutableIndexSet* sum, NSIndexPath* obj) {
        [sum addIndex:(NSUInteger)obj.section];
        return sum;
    }];

    return [[self.schemaManager.sections objectsAtIndexes:visibleSectionIndexes] wmf_mapAndRejectNil:^id (WMFExploreSection* obj) {
        return [self sectionControllerForSection:obj];
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

    self.tableView.scrollsToTop                 = YES;
    self.tableView.dataSource                   = nil;
    self.tableView.delegate                     = nil;
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 66.0;
    self.tableView.sectionFooterHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 50.0;

    [self.tableView registerNib:[WMFExploreSectionHeader wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self.tableView registerNib:[WMFExploreSectionFooter wmf_classNib]
     forHeaderFooterViewReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];

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

    [self createSectionSchemaIfNeeded];

    [[self visibleSectionControllers] enumerateObjectsUsingBlock:^(id<WMFExploreSectionController> _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([obj respondsToSelector:@selector(willDisplaySection)]) {
            [obj willDisplaySection];
        }
    }];

    if (self.isPreviewing) {
        [[PiwikTracker sharedInstance] wmf_logActionPreviewDismissedFromSource:self];
        self.isPreviewing = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // stop location manager from updating.
    [[self visibleSectionControllers] enumerateObjectsUsingBlock:^(id<WMFExploreSectionController> _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didEndDisplayingSection)]) {
            [obj didEndDisplayingSection];
        }
    }];
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
    if ([self wmf_isShowingEmptyView]) {
        return;
    }

    [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoFeed];

    @weakify(self);
    SCNetworkReachability().then(^{
        @strongify(self);
        [self wmf_hideEmptyView];
        [[self visibleSectionControllers] enumerateObjectsUsingBlock:^(id<WMFExploreSectionController>  _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
            @weakify(self);
            [obj fetchDataIfError].catch(^(NSError* error){
                @strongify(self);
                [self showOfflineEmptyViewAndReloadWhenReachable];
            });
        }];
    });
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [[self.schemaManager sections] count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    NSParameterAssert(controller);
    return [[controller items] count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[controller cellIdentifierForItemIndexPath:indexPath] forIndexPath:indexPath];
    [controller configureCell:cell atIndexPath:indexPath];
    return cell;
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

- (void)configureHeader:(WMFExploreSectionHeader*)header withStylingFromController:(id<WMFExploreSectionController>)controller {
    header.image                = [[controller headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.imageTintColor       = [controller headerIconTintColor];
    header.imageBackgroundColor = [controller headerIconBackgroundColor];

    NSMutableAttributedString* title = [[controller headerTitle] mutableCopy];
    [title addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderTitleFont] range:NSMakeRange(0, title.length)];
    header.title = title;

    NSMutableAttributedString* subTitle = [[controller headerSubTitle] mutableCopy];
    [subTitle addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderSubTitleFont] range:NSMakeRange(0, subTitle.length)];
    header.subTitle = subTitle;
}

- (nullable UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section; {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    if (!controller) {
        return nil;
    }

    WMFExploreSectionHeader* header = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self configureHeader:header withStylingFromController:controller];

    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:section];
    };

    if ([controller conformsToProtocol:@protocol(WMFHeaderMenuProviding)]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        [header.rightButton bk_addEventHandler:^(id sender) {
            [[(id < WMFHeaderMenuProviding >)controller menuActionSheet] showFromTabBar:self.navigationController.tabBarController.tabBar];
        } forControlEvents:UIControlEventTouchUpInside];
    } else if ([controller conformsToProtocol:@protocol(WMFHeaderActionProviding)]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[(id < WMFHeaderActionProviding >)controller headerButtonIcon] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        [header.rightButton bk_addEventHandler:^(id sender) {
            [(id < WMFHeaderActionProviding >)controller performHeaderButtonAction];
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
    if ([controller conformsToProtocol:@protocol(WMFMoreFooterProviding)]) {
        footer.visibleBackgroundView.alpha = 1.0;
        footer.moreLabel.text              = [(id < WMFMoreFooterProviding >)controller footerText];
        footer.moreLabel.textColor         = [UIColor wmf_exploreSectionFooterTextColor];
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

    if ([controller respondsToSelector:@selector(willDisplaySection)] && (![self isDisplayingCellsForSectionController:controller] || [self rowAtIndexPathIsOnlyRowVisibleInSection:indexPath])) {
        [controller willDisplaySection];
    }

    [self performSelector:@selector(fetchSectionIfShowing:) withObject:controller afterDelay:0.25 inModes:@[NSRunLoopCommonModes]];

    if ([controller conformsToProtocol:@protocol(WMFTitleProviding)]
        && (![controller respondsToSelector:@selector(titleForItemAtIndexPath:)]
            || [controller shouldSelectItemAtIndexPath:indexPath])) {
        MWKTitle* title = [(id < WMFTitleProviding >)controller titleForItemAtIndexPath:indexPath];
        if (title) {
            [[PiwikTracker sharedInstance] wmf_logActionScrollToItemInExploreSection:controller];
        }
    }
}

- (void)tableView:(UITableView*)tableView didEndDisplayingCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller respondsToSelector:@selector(didEndDisplayingSection)] && (![self isDisplayingCellsForSectionController:controller] || [self rowAtIndexPathIsOnlyRowVisibleInSection:indexPath])) {
        [controller didEndDisplayingSection];
    }

    NSArray<NSIndexPath*>* visibleIndexPathsInSection = [tableView.indexPathsForVisibleRows bk_select:^BOOL (NSIndexPath* i) {
        return i.section == indexPath.section;
    }];

    //the cell disappearing may still appear in this list
    visibleIndexPathsInSection = [visibleIndexPathsInSection bk_reject:^BOOL (id obj) {
        return [indexPath isEqual:obj];
    }];

    if (visibleIndexPathsInSection.count == 0) {
        DDLogInfo(@"Cancelling fetch for scrolled-away section: %@", controller);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchSectionIfShowing:) object:controller];
    }
}

- (BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    return [controller shouldSelectItemAtIndexPath:indexPath];
    return YES;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if (![controller shouldSelectItemAtIndexPath:indexPath]) {
        return;
    }

    [[PiwikTracker sharedInstance] wmf_logActionOpenItemInExploreSection:controller];
    UIViewController* vc = [controller detailViewControllerForItemAtIndexPath:indexPath];
    if ([vc isKindOfClass:[WMFArticleViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleViewController*)vc source:self animated:YES];
    } else {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - Refresh Control

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
    if (![self.refreshControl isRefreshing]) {
        return;
    }
    //Don't hide the spinner so quickly - so users can see the change
    //NOTE: CATransactions during tableview scrolling can cause jitters
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

#pragma mark - Create Schema

- (void)createSectionSchemaIfNeeded {
    if (self.schemaManager) {
        return;
    }
    if (!self.searchSite) {
        return;
    }
    if (!self.savedPages) {
        return;
    }
    if (!self.recentPages) {
        return;
    }
    if (!self.isViewLoaded) {
        return;
    }

    self.schemaManager = [WMFExploreSectionSchema schemaWithSite:self.searchSite
                                                      savedPages:self.savedPages
                                                         history:self.recentPages
                                                       blackList:[WMFRelatedSectionBlackList sharedBlackList]];
    self.schemaManager.delegate = self;
    [self loadSectionControllersForCurrentSectionSchema];
    [self updateSectionSchemaForce:NO];
    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    [self.tableView reloadData];
}

#pragma mark - Section Update

- (BOOL)updateSectionSchemaIfNeeded {
    return [self updateSectionSchemaForce:NO];
}

- (BOOL)updateSectionSchemaForce:(BOOL)force {
    if (!self.schemaManager) {
        return NO;
    }
    if (!self.isViewLoaded) {
        return NO;
    }
    [self.refreshControl beginRefreshing];
    return [self.schemaManager update:force];
}

#pragma mark - Delayed Fetching

- (void)fetchSectionIfShowing:(id<WMFExploreSectionController>)controller {
    if ([self isDisplayingCellsForSectionController:controller]) {
        DDLogVerbose(@"Fetching section after delay: %@", controller);
        @weakify(self);
        [controller fetchDataIfNeeded].catch(^(NSError* error){
            @strongify(self);
            if ([error wmf_isNetworkConnectionError]) {
                [self showOfflineEmptyViewAndReloadWhenReachable];
            }
        }).finally(^{
            [self resetRefreshControlWithCompletion:NULL];
        });
    } else {
        DDLogInfo(@"Section for controller %@ is no longer visible, skipping fetch.", controller);
    }
}

#pragma mark - Section Info

- (id<WMFExploreSectionController>)sectionControllerForSection:(WMFExploreSection*)section {
    id<WMFExploreSectionController> sectionController = [self.sectionControllerCache controllerForSection:section];
    if (!sectionController) {
        sectionController = [self.sectionControllerCache newControllerForSection:section];
        [self registerSectionForSectionController:sectionController];
    }
    return sectionController;
}

- (nullable id<WMFExploreSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    WMFExploreSection* section = self.schemaManager.sections[index];
    return [self sectionControllerForSection:section];
}

- (NSInteger)indexForSectionController:(id<WMFExploreSectionController>)controller {
    return [self.schemaManager.sections indexOfObject:[self.sectionControllerCache sectionForController:controller]];
}

#pragma mark - Section Loading

- (void)loadSectionControllersForCurrentSectionSchema {
    [self.schemaManager.sections enumerateObjectsUsingBlock:^(WMFExploreSection* obj, NSUInteger idx, BOOL* stop) {
        [self sectionControllerForSection:obj];
    }];
}

- (void)registerSectionForSectionController:(id<WMFExploreSectionController>)controller {
    if (!controller) {
        return;
    }

    [controller registerCellsInTableView:self.tableView];

    [self.KVOControllerNonRetaining unobserve:controller keyPath:WMF_SAFE_KEYPATH(controller, items)];

    [self.KVOControllerNonRetaining observe:controller keyPath:WMF_SAFE_KEYPATH(controller, items) options:0 block:^(WMFExploreViewController* observer, id < WMFExploreSectionController > object, NSDictionary* change) {
        NSUInteger sectionIndex = [observer indexForSectionController:controller];
        if (sectionIndex == NSNotFound) {
            return;
        }

        [observer.tableView reloadData];
        return;

        //TODO: enable animated updates. Currently causes more jitters

        NSIndexSet* indices = [change objectForKey:NSKeyValueChangeIndexesKey];
        if (indices == nil) {
            return;
        }
        NSMutableArray* indexPathArray = [NSMutableArray array];
        [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* _Nonnull stop) {
            NSIndexPath* newPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
            [indexPathArray addObject:newPath];
        }];

        [observer.tableView wmf_performUpdates:^{
            NSNumber* kind = [change objectForKey:NSKeyValueChangeKindKey];
            if ([kind integerValue] == NSKeyValueChangeInsertion) { // Rows were added
                [observer.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if ([kind integerValue] == NSKeyValueChangeRemoval) { // Rows were removed
                [observer.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
            } else { // Rows were Replaced
                [observer.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } withoutMovingCellAtIndexPath:[[self.tableView indexPathsForVisibleRows] firstObject]];
    }];
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
    id<WMFExploreSectionController, WMFMoreFooterProviding> articleSectionController = (id<WMFExploreSectionController, WMFMoreFooterProviding>)controllerForSection;

    UIViewController* moreVC = [articleSectionController moreViewController];
    [[PiwikTracker sharedInstance] wmf_logActionOpenMoreInExploreSection:articleSectionController];
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
            NSParameterAssert(controller.title);
            [self wmf_pushArticleWithTitle:controller.title dataStore:self.dataStore source:self animated:YES];
            break;
        }
    }
}

- (void)selectFirstRowInSection:(NSUInteger)section {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - WMFExploreSectionSchemaDelegate

- (void)sectionSchemaDidUpdateSections:(WMFExploreSectionSchema*)schema {
    [self wmf_hideEmptyView];
    [self loadSectionControllersForCurrentSectionSchema];
    [self.tableView reloadData];
}

- (void)sectionSchema:(WMFExploreSectionSchema*)schema didRemoveSection:(WMFExploreSection*)section atIndex:(NSUInteger)index {
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
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

    UIViewController* vc = [sectionController detailViewControllerForItemAtIndexPath:previewIndexPath];
    self.isPreviewing             = YES;
    self.sectionOfPreviewingTitle = sectionController;
    [[PiwikTracker sharedInstance] wmf_logActionPreviewFromSource:self];
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    [[PiwikTracker sharedInstance] wmf_logActionOpenItemInExploreSection:self.sectionOfPreviewingTitle];
    [[PiwikTracker sharedInstance] wmf_logActionPreviewCommittedFromSource:self];
    self.isPreviewing             = NO;
    self.sectionOfPreviewingTitle = nil;

    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleViewController*)viewControllerToCommit source:self animated:YES];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSString*)analyticsName {
    return @"Home";
}

@end

NS_ASSUME_NONNULL_END
