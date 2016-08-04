#import "WMFExploreViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <BlocksKit/BlocksKit+UIKit.h>
#import <Tweaks/FBTweakViewController.h>

#import "PiwikTracker+WMFExtensions.h"
#import "NSUserActivity+WMFExtensions.h"

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
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"
#import "MWKArticle.h"
#import "MWKLocationSearchResult.h"
#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"
#import "MWKLanguageLinkController.h"


// Views
#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"
#import "UITableView+WMFLockedUpdates.h"

// Child View Controllers
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFSettingsViewController.h"
#import "WMFTitleListDataSource.h"
#import "WMFArticleListTableViewController.h"
#import "WMFRelatedSectionController.h"
#import "UIViewController+WMFSearch.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"
#import "WMFColumnarCollectionViewLayout.h"

// Controllers
#import "WMFRelatedSectionBlackList.h"

#define ENABLE_RANDOM_DEBUGGING 0

#if ENABLE_RANDOM_DEBUGGING
#import "WMFFirstRandomViewController.h"
#endif

NSString * const WMFExploreEmptyFooterReuseIdentifier = @"empty";
static DDLogLevel const WMFExploreVCLogLevel = DDLogLevelInfo;
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFExploreVCLogLevel

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreViewController ()
<WMFExploreSectionSchemaDelegate,
 UIViewControllerPreviewingDelegate,
 WMFAnalyticsContextProviding,
 WMFAnalyticsViewNameProviding,
 UINavigationControllerDelegate,
WMFColumnarCollectionViewLayoutDelegate>

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

@property (nonatomic, strong, nullable) WMFExploreSectionSchema* schemaManager;

@property (nonatomic, strong) WMFExploreSectionControllerCache* sectionControllerCache;

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, assign) NSUInteger numberOfFailedFetches;
@property (nonatomic, assign) BOOL isWaitingForNetworkToReconnect;
@property (nonatomic, assign) CGPoint preNetworkTroubleScrollPosition;

@property (nonatomic, strong, nullable) id<WMFExploreSectionController> sectionOfPreviewingTitle;

@property (nonatomic, strong, nullable) AFNetworkReachabilityManager* reachabilityManager;

@property (nonatomic, readonly) NSArray* invisibleSections;

@property (nonatomic, strong) UIRefreshControl* refreshControl;

@end

@implementation WMFExploreViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.preNetworkTroubleScrollPosition = CGPointZero;
        UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b adjustsImageWhenHighlighted];
        UIImage* w = [UIImage imageNamed:@"W"];
        [b setImage:w forState:UIControlStateNormal];
        [b sizeToFit];
        @weakify(self);
        [b bk_addEventHandler:^(id sender) {
            @strongify(self);
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView                        = b;
        self.navigationItem.titleView.isAccessibilityElement = YES;
        self.navigationItem.titleView.accessibilityLabel     = MWLocalizedString(@"home-accessibility-label", nil);
        self.navigationItem.titleView.accessibilityTraits   |= UIAccessibilityTraitHeader;
        self.navigationItem.leftBarButtonItem                = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem               = [self wmf_searchBarButtonItem];
        self.reachabilityManager                             = [AFNetworkReachabilityManager manager];
        [self.reachabilityManager startMonitoring];
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

- (WMFExploreSectionControllerCache*)sectionControllerCache {
    NSParameterAssert(self.dataStore);
    if (!_sectionControllerCache) {
        _sectionControllerCache = [[WMFExploreSectionControllerCache alloc] initWithDataStore:self.dataStore];
    }
    return _sectionControllerCache;
}

- (NSUInteger)numberOfSectionsInExploreFeed{
    return [[self.schemaManager sections] count];
}

#pragma mark - Visibility

- (BOOL)isDisplayingCellsForSectionController:(id<WMFExploreSectionController>)controller {
    NSInteger sectionIndex = [self indexForSectionController:controller];
    if (sectionIndex == NSNotFound) {
        return NO;
    }
    return [self isDisplayingCellsForSection:sectionIndex];
}

- (BOOL)isDisplayingCellsForSection:(NSInteger)section {
    //NOTE: numberOfSectionsInCollectionView returns 0 when isWaitingForNetworkToReconnect == YES
    //so we need to bail here or the assertion below is tripped
    if (self.isWaitingForNetworkToReconnect) {
        return NO;
    }
    NSParameterAssert(section != NSNotFound);
    NSParameterAssert(section < [self numberOfSectionsInCollectionView:self.collectionView]);
    return [self.collectionView.indexPathsForVisibleItems bk_any:^BOOL (NSIndexPath* indexPath) {
        return indexPath.section == section;
    }];
}

- (BOOL)itemAtIndexPathIsOnlyItemVisibleInSection:(NSIndexPath*)indexPath {
    NSArray<NSIndexPath*>* visibleIndexPathsInSection = [self.collectionView.indexPathsForVisibleItems bk_select:^BOOL (NSIndexPath* i) {
        return i.section == indexPath.section;
    }];

    if ([visibleIndexPathsInSection count] == 1 && [[visibleIndexPathsInSection firstObject] isEqual:indexPath]) {
        return YES;
    } else {
        return NO;
    }
}

/**
 *  Check whether or not a section is going in or out of view.
 *
 *  @param indexPath The index path of the item which will or did end displaying.
 *
 *  @return @c YES if that section isn't displaying or the given item is the only one visible in its section, otherwise @c NO.
 */
- (BOOL)isVisibilityTransitioningForItemAtIndexPath:(NSIndexPath*)indexPath {
    return ![self isDisplayingCellsForSection:indexPath.section]
           || [self itemAtIndexPathIsOnlyItemVisibleInSection:indexPath];
}

- (NSArray*)visibleSectionControllers {
    NSIndexSet* visibleSectionIndexes = [[self.collectionView indexPathsForVisibleItems] bk_reduce:[NSMutableIndexSet indexSet] withBlock:^id (NSMutableIndexSet* sum, NSIndexPath* obj) {
        [sum addIndex:(NSUInteger)obj.section];
        return sum;
    }];

    if ([visibleSectionIndexes count] == 0) {
        return @[];
    }

    return [[self.schemaManager.sections objectsAtIndexes:visibleSectionIndexes] wmf_mapAndRejectNil:^id (WMFExploreSection* obj) {
        return [self sectionControllerForSection:obj];
    }];
}

- (NSArray*)invisibleSections {
    NSIndexSet* visibleSectionIndexes = [[self.collectionView indexPathsForVisibleItems] bk_reduce:[NSMutableIndexSet indexSet] withBlock:^id (NSMutableIndexSet* sum, NSIndexPath* obj) {
        [sum addIndex:(NSUInteger)obj.section];
        return sum;
    }];

    if ([visibleSectionIndexes count] == 0) {
        return self.schemaManager.sections;
    }

    NSMutableArray* invisibleSections = [self.schemaManager.sections mutableCopy];
    [invisibleSections removeObjectsAtIndexes:visibleSectionIndexes];
    return invisibleSections;
}

/**
 * Sends `willDisplaySection` to controllers whose sections are currently visible in the receiver's `collectionView`.
 *
 * Must be called when the view (re)appears: `viewDidApppear` and when the application is resumed (will enter foreground).
 *
 * `collectionView:willDisplayCell:forItemAtIndexPath:` will not trigger a `willDisplaySection` message, since it's only
 * designed to trigger when sections are *scrolled* in and out of view.  This is mostly because we only want to call
 * `willDisplaySection` _once_ for each section as its (potentially multiple) cells scroll into view.
 *
 * This was manifested in the following issue: https://phabricator.wikimedia.org/T128217
 *
 * @see isVisibilityTransitioningForItemAtIndexPath:
 */
- (void)sendWillDisplayToVisibleSectionControllers {
    [[self visibleSectionControllers] bk_each:^(id<WMFExploreSectionController> _Nonnull controller) {
        if ([controller respondsToSelector:@selector(willDisplaySection)]) {
            DDLogInfo(@"Manually sending willDisplaySection to controller %@", controller);
            [controller willDisplaySection];
        }
    }];
}

#pragma mark - Actions

- (void)showSettings {
    UINavigationController* settingsContainer =
        [[UINavigationController alloc] initWithRootViewController:
         [WMFSettingsViewController settingsViewControllerWithDataStore:self.dataStore]];
    settingsContainer.delegate = self;
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
}

- (BOOL)canScrollToTop {
    if (self.isWaitingForNetworkToReconnect) {
        return NO;
    }
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:0];
    NSParameterAssert(controller);
    return [[controller items] count] > 0;
}

- (void)didTapSettingsButton:(UIBarButtonItem*)sender {
    [self showSettings];
}

#pragma mark - UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl bk_addEventHandler:^(id sender) {
        [self updateSectionSchemaForce:YES];
    } forControlEvents:UIControlEventValueChanged];

    [self resetRefreshControlWithCompletion:NULL];
        
    self.collectionView.scrollsToTop = YES;
    self.collectionView.dataSource   = nil;
    self.collectionView.delegate     = nil;

    [self.collectionView registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];

    [self.collectionView registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFExploreEmptyFooterReuseIdentifier];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForegroundWithNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tweaksDidChangeWithNotification:)
                                                 name:FBTweakShakeViewControllerDidDismissNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appLanguageDidChangeWithNotification:)
                                                 name:WMFPreferredLanguagesDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.recentPages);
    NSParameterAssert(self.savedPages);
    [super viewDidAppear:animated];

    [self.reachabilityManager startMonitoring];

    if ([self wmf_isShowingEmptyView]) {
        return;
    }

    /*
       NOTE: Section should only be _created_ on `viewDidAppear`, which is not the same as updating.  Updates only happen
       between sessions (i.e. when resumed from background or relaunched).
     */
    [self createSectionSchemaIfNeeded];

    [self sendWillDisplayToVisibleSectionControllers];

    [[PiwikTracker wmf_configuredInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_exploreViewActivity]];
#if ENABLE_RANDOM_DEBUGGING
    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSite:[MWKSite siteWithLanguage:@"en"] dataStore:self.dataStore];
    [self wmf_pushViewController:vc animated:YES];
#endif
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.reachabilityManager stopMonitoring];

    // stop location manager from updating.
    [[self visibleSectionControllers] bk_each:^(id<WMFExploreSectionController> _Nonnull obj) {
        if ([obj respondsToSelector:@selector(didEndDisplayingSection)]) {
            DDLogDebug(@"Sending didEndDisplayingSection to controller %@ on view disappearance", obj);
            [obj didEndDisplayingSection];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForPreviewingIfAvailable];
    for (UICollectionViewCell* cell in self.collectionView.visibleCells) {
        cell.selected = NO;
    }
    [[NSUserDefaults standardUserDefaults] wmf_setOpenArticleURL:nil];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterForPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self removeInvisibleSectionsFromCache];
}

#pragma mark - Notifications

- (void)applicationWillEnterForegroundWithNotification:(NSNotification*)note {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    [self sendWillDisplayToVisibleSectionControllers];
}

- (void)removeInvisibleSectionsFromCache {
    [self.sectionControllerCache removeSections:self.invisibleSections];
}

- (void)appLanguageDidChangeWithNotification:(NSNotification*)note {
    [self createSectionSchemaIfNeeded];
    [self.schemaManager updateSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL]];
}

- (void)tweaksDidChangeWithNotification:(NSNotification*)note {
    [self updateSectionSchemaIfNeeded];
}

#pragma mark - Offline Handling

- (void)showOfflineEmptyViewAndReloadWhenReachable {
    NSParameterAssert(self.isViewLoaded);
    if ([self wmf_isShowingEmptyView]) {
        return;
    }

    if (self.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable) {
        return;
    }

    if (self.numberOfFailedFetches < 3) {
        self.numberOfFailedFetches++;
        return;
    }

    self.preNetworkTroubleScrollPosition = self.collectionView.contentOffset;
    self.isWaitingForNetworkToReconnect  = YES;
    [self.refreshControl endRefreshing];
    [self.collectionView reloadData];

    [self wmf_showEmptyViewOfType:WMFEmptyViewTypeNoFeed];
    @weakify(self);
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                @strongify(self);
                self.numberOfFailedFetches = 0;
                self.isWaitingForNetworkToReconnect = NO;
                [self.collectionView reloadData];
                [self.collectionView setContentOffset:self.preNetworkTroubleScrollPosition animated:NO];
                self.preNetworkTroubleScrollPosition = CGPointZero;
                [self wmf_hideEmptyView];

                [[self visibleSectionControllers] enumerateObjectsUsingBlock:^(id<WMFExploreSectionController>  _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                    @weakify(self);
                    [obj resetData];
                    [obj fetchDataIfError].catch(^(NSError* error){
                        @strongify(self);
                        if ([error wmf_isNetworkConnectionError]) {
                            [self showOfflineEmptyViewAndReloadWhenReachable];
                        }
                    });
                }];
            }
            break;
            default:
                break;
        }
    }];
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    if (self.isWaitingForNetworkToReconnect) {
        return 0;
    }
    return [[self.schemaManager sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isWaitingForNetworkToReconnect) {
        return 0;
    }
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    NSParameterAssert(controller);
    return [[controller items] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[controller cellIdentifierForItemIndexPath:indexPath] forIndexPath:indexPath];
    [controller configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    return [controller estimatedRowHeight];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    return 66;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    
    if (!controller) {
        return 0;
    }
    
    if ([controller conformsToProtocol:@protocol(WMFMoreFooterProviding)] && (![controller respondsToSelector:@selector(isFooterEnabled)] || [(id<WMFMoreFooterProviding>) controller isFooterEnabled])) {
        return 50;
    } else {
        return 0;
    }
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

- (nonnull UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView viewForSectionHeaderAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView viewForSectionFooterAtIndexPath:indexPath];
    } else {
        assert(false);
        return [UICollectionReusableView new];
    }
}

- (nonnull UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if (!controller) {
        return nil;
    }

    WMFExploreSectionHeader* header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];

    [self configureHeader:header withStylingFromController:controller];

    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:indexPath.section];
    };

    if ([controller conformsToProtocol:@protocol(WMFHeaderMenuProviding)]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        @weakify(controller);
        [header.rightButton bk_addEventHandler:^(id sender) {
            @strongify(controller);
            @strongify(self);
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                UIAlertController *menuActionSheet = [(id < WMFHeaderMenuProviding >)controller menuActionSheet];
                menuActionSheet.modalPresentationStyle = UIModalPresentationPopover;
                menuActionSheet.popoverPresentationController.sourceView = sender;
                menuActionSheet.popoverPresentationController.sourceRect = [sender bounds];
                menuActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            } else {
                UIAlertController *menuActionSheet = [(id < WMFHeaderMenuProviding >)controller menuActionSheet];
                menuActionSheet.popoverPresentationController.sourceView = self.navigationController.tabBarController.tabBar.superview;
                menuActionSheet.popoverPresentationController.sourceRect = self.navigationController.tabBarController.tabBar.frame;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            }
        } forControlEvents:UIControlEventTouchUpInside];
    } else if ([controller conformsToProtocol:@protocol(WMFHeaderActionProviding)] && (![controller respondsToSelector:@selector(isHeaderActionEnabled)] || [(id <WMFHeaderActionProviding>) controller isHeaderActionEnabled])) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[(id < WMFHeaderActionProviding >)controller headerButtonIcon] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        @weakify(controller);
        [header.rightButton bk_addEventHandler:^(id sender) {
            @strongify(controller);
            [(id < WMFHeaderActionProviding >)controller performHeaderButtonAction];
        } forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    }

    return header;
}

- (nonnull UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    if (!controller) {
        return nil;
    }
   
    if ([controller conformsToProtocol:@protocol(WMFMoreFooterProviding)] && (![controller respondsToSelector:@selector(isFooterEnabled)] || [(id<WMFMoreFooterProviding>) controller isFooterEnabled])) {
         WMFExploreSectionFooter* footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
        footer.visibleBackgroundView.alpha = 1.0;
        footer.moreLabel.text              = [(id < WMFMoreFooterProviding >)controller footerText];
        footer.moreLabel.textColor         = [UIColor wmf_exploreSectionFooterTextColor];
        @weakify(self);
        footer.whenTapped = ^{
            @strongify(self);
            [self didTapFooterInSection:indexPath.section];
        };
        return footer;
    } else {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFExploreEmptyFooterReuseIdentifier forIndexPath:indexPath];
    }
 
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller respondsToSelector:@selector(willDisplaySection)]) {
        DDLogDebug(@"Sending willDisplaySection for controller %@ at indexPath %@", controller, indexPath);
        [controller willDisplaySection];
    }

    [self performSelector:@selector(fetchSectionIfShowing:) withObject:controller afterDelay:0.25 inModes:@[NSRunLoopCommonModes]];

    if ([controller conformsToProtocol:@protocol(WMFTitleProviding)]
        && (![controller respondsToSelector:@selector(urlForItemAtIndexPath:)]
            || [controller shouldSelectItemAtIndexPath:indexPath])) {
        NSURL* articleURL = [(id < WMFTitleProviding >)controller urlForItemAtIndexPath:indexPath];
        if (articleURL) {
            [[PiwikTracker wmf_configuredInstance] wmf_logActionImpressionInContext:self contentType:controller];
        }
    }
}

- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingCell:(UICollectionViewCell*)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

    if ([controller respondsToSelector:@selector(didEndDisplayingSection)]) {
        if ([self isVisibilityTransitioningForItemAtIndexPath:indexPath]) {
            DDLogDebug(@"Sending didEndDisplayingSection for controller %@ at indexPath %@", controller, indexPath);
            [controller didEndDisplayingSection];
        } else {
            DDLogDebug(@"Skipping calling didEndDisplaySection for controller %@ indexPath %@", controller, indexPath);
        }
    }

    NSArray<NSIndexPath*>* visibleIndexPathsInSection = [collectionView.indexPathsForVisibleItems bk_select:^BOOL (NSIndexPath* i) {
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

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if (controller != nil) {
        return [controller shouldSelectItemAtIndexPath:indexPath];
    } else {
        return YES;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self collectionView:collectionView shouldSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    if (![controller shouldSelectItemAtIndexPath:indexPath]) {
        return;
    }

    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:controller];
    UIViewController* vc = [controller detailViewControllerForItemAtIndexPath:indexPath];
    if ([vc isKindOfClass:[WMFArticleViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleViewController*)vc animated:YES];
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
    dispatchOnMainQueueAfterDelayInSeconds(1.0, ^{
        [self.refreshControl endRefreshing];
        if (completion) {
            completion();
        }
    });
}

#pragma mark - Create Schema

- (void)createSectionSchemaIfNeeded {
    if (self.schemaManager) {
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

    self.schemaManager = [WMFExploreSectionSchema schemaWithSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL]
                                                      savedPages:self.savedPages
                                                         history:self.recentPages
                                                       blackList:[WMFRelatedSectionBlackList sharedBlackList]];
    self.schemaManager.delegate = self;
    [self loadSectionControllersForCurrentSectionSchema];
    self.collectionView.dataSource = self;
    self.collectionView.delegate   = self;

    [self.collectionView reloadData];
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
    BOOL const willUpdate = [self.schemaManager update:force];
    if (willUpdate) {
        [self.refreshControl beginRefreshing];
    }
    return willUpdate;
}

#pragma mark - Delayed Fetching

- (void)fetchSectionIfShowing:(id<WMFExploreSectionController>)controller {
    if ([self isDisplayingCellsForSectionController:controller]) {
        DDLogDebug(@"Fetching section after delay: %@", controller);
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
    id<WMFExploreSectionController> sectionController =
        [self.sectionControllerCache getOrCreateControllerForSection:section
                                                       creationBlock:^(id < WMFExploreSectionController > _Nonnull newController) {
        [self registerSectionForSectionController:newController];
    }];
    return sectionController;
}

- (nullable id<WMFExploreSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    if (index >= self.schemaManager.sections.count) {
        return nil;
    }
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

    [controller registerCellsInCollectionView:self.collectionView];

    [self.KVOControllerNonRetaining unobserve:controller keyPath:WMF_SAFE_KEYPATH(controller, items)];

    [self.KVOControllerNonRetaining observe:controller
                                    keyPath:WMF_SAFE_KEYPATH(controller, items)
                                    options:0
                                      block:^(WMFExploreViewController* observer,
                                              id < WMFExploreSectionController > observedController,
                                              NSDictionary* _) {
        NSUInteger sectionIndex = [observer indexForSectionController:observedController];
        if (sectionIndex != NSNotFound && [observer isDisplayingCellsForSection:sectionIndex]) {
            DDLogDebug(@"Reloading table to display results in controller %@", observedController);
            [observer.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
        }
    }];
}

- (void)didTapFooterInSection:(NSUInteger)section {
    id<WMFExploreSectionController> controllerForSection = [self sectionControllerForSectionAtIndex:section];
    NSParameterAssert(controllerForSection);
    if (!controllerForSection) {
        DDLogError(@"Unexpected footer tap for missing section %lu.", (unsigned long)section);
        return;
    }
    if (![controllerForSection respondsToSelector:@selector(moreViewController)]) {
        return;
    }
    id<WMFExploreSectionController, WMFMoreFooterProviding> articleSectionController = (id<WMFExploreSectionController, WMFMoreFooterProviding>)controllerForSection;

    UIViewController* moreVC = [articleSectionController moreViewController];
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughMoreInContext:self contentType:controllerForSection];
    [self.navigationController pushViewController:moreVC animated:YES];
}

- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFExploreSection* homeSection = self.schemaManager.sections[section];
    if (homeSection.type == WMFExploreSectionTypeNearby) {
        [self didTapFooterInSection:section];
    } else if (homeSection.type == WMFExploreSectionTypeHistory || homeSection.type == WMFExploreSectionTypeSaved) {
        [self wmf_pushArticleWithURL:homeSection.articleURL dataStore:self.dataStore animated:YES];
    } else {
        [self selectFirstItemInSection:section];
    }
}

- (void)selectFirstItemInSection:(NSUInteger)section {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - WMFExploreSectionSchemaDelegate

- (void)sectionSchemaDidUpdateSections:(WMFExploreSectionSchema*)schema {
    [self wmf_hideEmptyView];
    [self.sectionControllerCache removeAllSectionsExcept:schema.sections];
    [self loadSectionControllersForCurrentSectionSchema];
    [self.collectionView reloadData];
    [[self visibleSectionControllers] bk_each:^(id<WMFExploreSectionController> _Nonnull obj) {
        [obj fetchDataIfError];
    }];
}

- (void)sectionSchema:(WMFExploreSectionSchema*)schema didRemoveSection:(WMFExploreSection*)section atIndex:(NSUInteger)index {
    [self.sectionControllerCache removeSection:section];
    [self.collectionView reloadData];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    NSIndexPath* previewIndexPath                     = [self.collectionView indexPathForItemAtPoint:location];
    id<WMFExploreSectionController> sectionController = [self sectionControllerForSectionAtIndex:previewIndexPath.section];

    if (![sectionController shouldSelectItemAtIndexPath:previewIndexPath]) {
        return nil;
    }

    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:previewIndexPath].frame;

    UIViewController* vc = [sectionController detailViewControllerForItemAtIndexPath:previewIndexPath];
    self.sectionOfPreviewingTitle = sectionController;
    [[PiwikTracker wmf_configuredInstance] wmf_logActionPreviewInContext:self contentType:sectionController];
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController*)viewControllerToCommit {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:self.sectionOfPreviewingTitle];
    self.sectionOfPreviewingTitle = nil;

    if ([viewControllerToCommit isKindOfClass:[WMFArticleViewController class]]) {
        [self wmf_pushArticleViewController:(WMFArticleViewController*)viewControllerToCommit animated:YES];
    } else {
        [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSString*)analyticsContext {
    return @"Explore";
}

- (NSString*)analyticsName {
    return [self analyticsContext];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated {
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
}

#pragma mark - UIRefreshControl

- (void)setRefreshControl:(UIRefreshControl*)refreshControl {
    [_refreshControl removeFromSuperview];

    _refreshControl = refreshControl;

    if (_refreshControl) {
        _refreshControl.layer.zPosition = -100;
        [self.collectionView addSubview:_refreshControl];
    }
}

@end

NS_ASSUME_NONNULL_END