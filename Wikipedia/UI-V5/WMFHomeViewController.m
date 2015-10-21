#import "WMFHomeViewController.h"

#import "Wikipedia-Swift.h"

// Frameworks
@import SelfSizingWaterfallCollectionViewLayout;
@import SSDataSources;
@import Tweaks;

// Sections
#import "WMFNearbySectionController.h"
#import "WMFRelatedSectionController.h"
#import "WMFContinueReadingSectionController.h"
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
#import "WMFArticleListDataSource.h"
#import "WMFArticleListCollectionViewController.h"

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
@property (nonatomic, strong) NSMutableDictionary<NSString*, id<WMFHomeSectionController> >* sectionControllersBySectionID;
@property (nonatomic, strong) NSMutableDictionary< WMFHomeSection*, id<WMFHomeSectionController> >* sectionControllersBySection;

@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, strong) NSOperationQueue* collectionViewUpdateQueue;

@end

@implementation WMFHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.sectionControllersBySection removeAllObjects];
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

- (NSString* __nullable)title {
    // TODO: localize
    return @"Home";
}

#pragma mark - Accessors

+ (UIEdgeInsets)defaultSectionInsets {
    return UIEdgeInsetsMake(1.0, 0.0, 0.0, 0.0);
}

- (UIBarButtonItem*)settingsBarButtonItem {
    // TODO: localize
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    _searchSite                             = searchSite;
    self.nearbySectionController.searchSite = searchSite;
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
                                                                    locationManager  :self.locationManager];
        [_nearbySectionController setSavedPageList:self.savedPages];
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

- (NSMutableDictionary<NSString*, id<WMFHomeSectionController> >*)sectionControllersBySectionID {
    if (!_sectionControllersBySectionID) {
        _sectionControllersBySectionID = [NSMutableDictionary new];
    }
    return _sectionControllersBySectionID;
}

- (NSMutableDictionary<WMFHomeSection*, id<WMFHomeSectionController> >*)sectionControllersBySection {
    if (_sectionControllersBySection == nil) {
        _sectionControllersBySection = [NSMutableDictionary new];
    }
    return _sectionControllersBySection;
}

- (SelfSizingWaterfallCollectionViewLayout*)flowLayout {
    return (id)self.collectionView.collectionViewLayout;
}

- (CGFloat)contentWidth {
    CGFloat width = self.view.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
    return width;
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
    WMFArticleListCollectionViewController* extendedList = [[WMFArticleListCollectionViewController alloc] init];
    extendedList.dataStore   = self.dataStore;
    extendedList.savedPages  = self.savedPages;
    extendedList.recentPages = self.recentPages;
    extendedList.dataSource  = [controllerForSection extendedListDataSource];
    [self.navigationController pushViewController:extendedList animated:YES];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    queue.qualityOfService            = NSQualityOfServiceUserInteractive;
    self.collectionViewUpdateQueue    = queue;


    self.collectionView.dataSource = nil;

    [self flowLayout].estimatedItemHeight = 380;
    [self flowLayout].numberOfColumns     = 1;
    [self flowLayout].sectionInset        = [[self class] defaultSectionInsets];
    [self flowLayout].minimumLineSpacing  = 1.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];

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
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
    } completion:NULL];
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

    @weakify(self);

    self.dataSource.cellCreationBlock = (id) ^ (id object, id parentView, NSIndexPath * indexPath){
        @strongify(self);
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        return [controller dequeueCellForCollectionView:self.collectionView atIndexPath:indexPath];
    };

    self.dataSource.cellConfigureBlock = ^(id cell, id object, id parentView, NSIndexPath* indexPath){
        @strongify(self);
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        NSParameterAssert(controller);
        [controller configureCell:cell withObject:object inCollectionView:parentView atIndexPath:indexPath];
    };

    self.dataSource.collectionSupplementaryCreationBlock = ^UICollectionReusableView*(NSString* kind,
                                                                                      UICollectionView* cv,
                                                                                      NSIndexPath* indexPath) {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            return [WMFHomeSectionHeader supplementaryViewForCollectionView:cv kind:kind indexPath:indexPath];
        } else {
            return [WMFHomeSectionFooter supplementaryViewForCollectionView:cv kind:kind indexPath:indexPath];
        }
    };

    self.dataSource.collectionSupplementaryConfigureBlock = ^(id view,
                                                              NSString* kind,
                                                              UICollectionView* cv,
                                                              NSIndexPath* indexPath){
        @strongify(self);
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            WMFHomeSectionHeader* header = view;
            header.icon.image     = [[controller headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            header.icon.tintColor = [UIColor wmf_homeSectionHeaderTextColor];
            NSMutableAttributedString* title = [[controller headerText] mutableCopy];
            [title addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0] range:NSMakeRange(0, title.length)];
            [title addAttribute:NSForegroundColorAttributeName value:[UIColor wmf_homeSectionHeaderTextColor] range:NSMakeRange(0, title.length)];
            header.titleView.attributedText = title;
            header.titleView.tintColor      = [UIColor wmf_homeSectionHeaderLinkTextColor];
            header.titleView.delegate       = self;
        } else {
            WMFHomeSectionFooter* footer = view;
            if ([controller respondsToSelector:@selector(footerText)]) {
                footer.moreLabel.text      = controller.footerText;
                footer.moreLabel.textColor = [UIColor wmf_homeSectionFooterTextColor];
                @weakify(self);
                footer.whenTapped = ^{
                    @strongify(self);
                    [self didTapFooterInSection:indexPath.section];
                };
            }
        }
    };

    [self.collectionView registerNib:[WMFHomeSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFHomeSectionHeader wmf_nibName]];
    [self.collectionView registerNib:[WMFHomeSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFHomeSectionFooter wmf_nibName]];

    self.dataSource.collectionView = self.collectionView;
    [self reloadSectionsOnOperationQueue];
    [self.schemaManager update];
}

#pragma mark - Sections

- (id<WMFHomeSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    SSSection* section = [self.dataSource sectionAtIndex:index];
    return self.sectionControllersBySectionID[section.sectionIdentifier];
}

- (NSInteger)indexForSectionController:(id<WMFHomeSectionController>)controller {
    return (NSInteger)[self.dataSource indexOfSectionWithIdentifier:[controller sectionIdentifier]];
}

- (id<WMFHomeSectionController>)sectionControllerForSection:(WMFHomeSection*)section {
    switch (section.type) {
        case WMFHomeSectionTypeHistory:
        case WMFHomeSectionTypeSaved:
            return [self relatedSectionControllerForSection:section];
            break;
        case WMFHomeSectionTypeNearby:
            return self.nearbySectionController;
            break;
        case WMFHomeSectionTypeContinueReading:
            return [self continueReadingSectionControllerForSection:section];
            break;
        case WMFHomeSectionTypeToday:
        case WMFHomeSectionTypeRandom:
        default:
            return nil;
            break;
    }
}

- (WMFRelatedSectionController*)relatedSectionControllerForSection:(WMFHomeSection*)section {
    WMFRelatedSectionController* controller = [self.sectionControllersBySection bk_match:^BOOL (WMFHomeSection* key, id < WMFHomeSectionController > obj) {
        return [self section:section isLikeSection:key];
    }];

    if (!controller) {
        controller = [[WMFRelatedSectionController alloc] initWithArticleTitle:section.title
                                                                      delegate:self];
        [controller setSavedPageList:self.savedPages];
        self.sectionControllersBySection[section] = controller;
    }

    return controller;
}

- (WMFContinueReadingSectionController*)continueReadingSectionControllerForSection:(WMFHomeSection*)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleTitle:item.title dataStore:self.dataStore delegate:self];
}

#pragma mark - Section Loading

- (void)reloadSectionsOnOperationQueue {
    @weakify(self);
    [self.collectionViewUpdateQueue wmf_addOperationWithAsyncBlock:^(WMFAsyncBlockOperation* _Nonnull operation) {
        dispatchOnMainQueue(^{
            @strongify(self);
            [self reloadSectionsWithCompletion:^{
                [operation finish];
            }];
        });
    }];
}

- (void)reloadSectionsWithCompletion:(nullable dispatch_block_t)completion {
    WMFHomeSection* sectionToRestore = [self currentFocusedSection];
    [self.sectionControllersBySectionID enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id < WMFHomeSectionController > _Nonnull obj, BOOL* _Nonnull stop) {
        [self unloadSectionForSectionController:obj];
    }];

    [self.collectionView performBatchUpdates:^{
        [self.schemaManager.sections enumerateObjectsUsingBlock:^(WMFHomeSection* obj, NSUInteger idx, BOOL* stop) {
            [self loadSectionForSectionController:[self sectionControllerForSection:obj]];
        }];
    } completion:^(BOOL finished) {
        WMFHomeSection* newSectionToRestore = [self sectionMostLikeSection:sectionToRestore];
        [self scrollToSection:newSectionToRestore animated:NO];

        if (completion) {
            completion();
        }
    }];
}

- (void)loadSectionForSectionController:(id<WMFHomeSectionController>)controller {
    if (!controller) {
        return;
    }
    self.sectionControllersBySectionID[controller.sectionIdentifier] = controller;

    [controller registerCellsInCollectionView:self.collectionView];

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
        [self.sectionControllersBySectionID removeObjectForKey:controller.sectionIdentifier];
    }

    if (index == NSNotFound) {
        return;
    }

    [self.dataSource removeSectionAtIndex:index];
}

#pragma mark - Focused Section Restore

- (WMFHomeSection*)currentFocusedSection {
    // If we are close to the top, no reason to do this.
    if (self.collectionView.contentOffset.y < 44) {
        return nil;
    }

    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    center.y += self.collectionView.contentOffset.y;

    NSIndexPath* indexpath = [self.collectionView indexPathForItemAtPoint:center];
    if (!indexpath) {
        return nil;
    }

    WMFHomeSection* section = [[self.schemaManager sections] wmf_safeObjectAtIndex:indexpath.section];
    return section;
}

- (BOOL)section:(WMFHomeSection*)section isLikeSection:(WMFHomeSection*)otherSection {
    switch (section.type) {
        case WMFHomeSectionTypeContinueReading:
        case WMFHomeSectionTypeToday:
        case WMFHomeSectionTypeRandom:
        case WMFHomeSectionTypeNearby: {
            return otherSection.type == section.type;
        }
        break;
        case WMFHomeSectionTypeHistory:
        case WMFHomeSectionTypeSaved: {
            return [otherSection.title isEqualToTitle:section.title];
        }
        break;
        default: {
            return NO;
        }
        break;
    }
}

- (WMFHomeSection*)sectionMostLikeSection:(WMFHomeSection*)section {
    if (!section) {
        return nil;
    }

    WMFHomeSection* newSection = [[self.schemaManager sections] bk_match:^BOOL (WMFHomeSection* obj) {
        return [self section:section isLikeSection:obj];
    }];

    return newSection;
}

#pragma mark - Scroll To Section

- (void)scrollToSection:(WMFHomeSection*)section animated:(BOOL)animated {
    if (!section) {
        return;
    }
    NSUInteger sectionIndex = [[self.schemaManager sections] indexOfObject:section];
    if (sectionIndex == NSNotFound) {
        return;
    }

    if ([self.collectionView numberOfItemsInSection:sectionIndex] == 0) {
        return;
    }

    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section {
    CGFloat height = (section == 0) ? 104 : 78;
    return CGSizeMake([self contentWidth], height);
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section {
    id<WMFHomeSectionController> controllerForSection = [self sectionControllerForSectionAtIndex:section];
    if ([controllerForSection respondsToSelector:@selector(footerText)]) {
        CGFloat height = (section == self.dataSource.numberOfSections - 1) ? 104 : 78;
        return CGSizeMake([self contentWidth], height);
    } else {
        return CGSizeZero;
    }
}

- (BOOL)collectionView:(UICollectionView*)collectionView shouldSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    if ([controller respondsToSelector:@selector(shouldSelectItemAtIndex:)]) {
        return [controller shouldSelectItemAtIndex:indexPath.item];
    }
    return YES;
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
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

- (CGFloat)maxItemWidth {
    CGSize screenBoundsSize           = [[UIScreen mainScreen] bounds].size;
    UIEdgeInsets defaultSectionInsets = [[self class] defaultSectionInsets];
    return MAX(screenBoundsSize.height, screenBoundsSize.width) - defaultSectionInsets.left - defaultSectionInsets.right;
}

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }

    [self.collectionView performBatchUpdates:^{
        [self.dataSource setItems:items inSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }

    [self.collectionView performBatchUpdates:^{
        [self.dataSource appendItems:items toSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes {
    NSInteger section = [self indexForSectionController:controller];
    NSAssert(section != NSNotFound, @"Unknown section calling delegate");
    if (section == NSNotFound) {
        return;
    }
    [self.collectionView performBatchUpdates:^{
        [self.dataSource reloadCellsAtIndexes:indexes inSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller enumerateVisibleCells:(WMFHomeSectionCellEnumerator)enumerator {
    NSInteger section = [self indexForSectionController:controller];
    if (section == NSNotFound) {
        return;
    }
    [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL* stop) {
        if (obj.section == section) {
            enumerator([self.collectionView cellForItemAtIndexPath:obj], obj);
        }
    }];
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
    NSIndexPath* previewIndexPath                  = [(UICollectionView*)previewingContext.sourceView indexPathForItemAtPoint:location];
    id<WMFHomeSectionController> sectionController = [self sectionControllerForSectionAtIndex:previewIndexPath.section];
    if (!sectionController) {
        return nil;
    }
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
