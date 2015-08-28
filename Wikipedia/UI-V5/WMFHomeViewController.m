

#import "WMFHomeViewController.h"

#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "WMFRelatedSearchFetcher.h"

#import "WMFNearbySectionController.h"
#import "WMFRelatedSectionController.h"
#import "WMFSettingsViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

#import <SSDataSources/SSDataSources.h>
#import "SSSectionedDataSource+WMFSectionConvenience.h"

#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"

#import "MWKSite.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"
#import "MWKTitle.h"
#import "MWKArticle.h"

#import "MWKLocationSearchResult.h"

#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

#import "UIView+WMFDefaultNib.h"
#import "WMFHomeSectionHeader.h"
#import "WMFHomeSectionFooter.h"

#import "WMFArticleContainerViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeViewController ()<WMFHomeSectionControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong, null_resettable) WMFNearbySectionController* nearbySectionController;
@property (nonatomic, strong, null_resettable) WMFRelatedSectionController* recentSectionController;
@property (nonatomic, strong, null_resettable) WMFRelatedSectionController* savedSectionController;

@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, strong) NSMutableDictionary* sectionControllers;

@end

@implementation WMFHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.navigationItem.titleView =
            [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wikipedia"]];
        self.navigationItem.rightBarButtonItems = @[
            [self settingsBarButtonItem]
        ];
    }
    return self;
}

- (NSString*)title {
    // TODO: localize
    return @"Home";
}

#pragma mark - Accessors

- (UIBarButtonItem*)settingsBarButtonItem {
    // TODO: localize
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (void)setSearchSite:(MWKSite* __nonnull)searchSite {
    _searchSite                             = searchSite;
    self.nearbySectionController.searchSite = searchSite;
}

- (WMFNearbySectionController*)nearbySectionController {
    if (!_nearbySectionController) {
        _nearbySectionController          = [[WMFNearbySectionController alloc] initWithSite:self.searchSite LocationManager:self.locationManager locationSearchFetcher:self.locationSearchFetcher];
        _nearbySectionController.delegate = self;
    }
    return _nearbySectionController;
}

- (WMFRelatedSectionController*)recentSectionController {
    if (!_recentSectionController) {
        MWKTitle* recentTite = [self mostRecentReadArticle];
        if (!recentTite) {
            return nil;
        }
        WMFRelatedSearchFetcher* fetcher = [[WMFRelatedSearchFetcher alloc] init];
        _recentSectionController          = [[WMFRelatedSectionController alloc] initWithArticleTitle:recentTite relatedSearchFetcher:fetcher];
        _recentSectionController.delegate = self;
    }
    return _recentSectionController;
}

- (WMFRelatedSectionController*)savedSectionController {
    if (!_savedSectionController) {
        MWKTitle* recentTite = [self mostRecentSavedArticle];
        if (!recentTite) {
            return nil;
        }
        WMFRelatedSearchFetcher* fetcher = [[WMFRelatedSearchFetcher alloc] init];
        _savedSectionController          = [[WMFRelatedSectionController alloc] initWithArticleTitle:recentTite relatedSearchFetcher:fetcher];
        _savedSectionController.delegate = self;
    }
    return _savedSectionController;
}

- (WMFLocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [[WMFLocationManager alloc] init];
    }
    return _locationManager;
}

- (WMFLocationSearchFetcher*)locationSearchFetcher {
    if (!_locationSearchFetcher) {
        _locationSearchFetcher = [[WMFLocationSearchFetcher alloc] init];
    }
    return _locationSearchFetcher;
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

#pragma mark - UiViewController

#pragma mark - Related Articles

- (BOOL)shouldReloadRecentArticleSection {
    if ([[[self.recentPages mostRecentEntry] title] isEqualToTitle:self.recentSectionController.title]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldReloadSavedArticleSection {
    if ([[[self.savedPages mostRecentEntry] title] isEqualToTitle:self.savedSectionController.title]) {
        return NO;
    }
    return YES;
}

- (void)reloadRelatedArticlesForRecentArticles {
    if ([self shouldReloadRecentArticleSection]) {
        [self unloadSectionForSectionController:self.recentSectionController];
        self.recentSectionController = nil;
        if ([self.dataSource numberOfSections] > 0) {
            [self insertSectionForSectionController:self.recentSectionController atIndex:0];
        } else {
            [self loadSectionForSectionController:self.recentSectionController];
        }
    }
}

- (void)reloadRelatedArticlesForSavedArticles {
    if ([self shouldReloadSavedArticleSection]) {
        [self unloadSectionForSectionController:self.savedSectionController];
        self.savedSectionController = nil;
        [self loadSectionForSectionController:self.savedSectionController];
    }
}

- (MWKTitle*)mostRecentReadArticle {
    MWKHistoryEntry* latest = [self.recentPages mostRecentEntry];
    return latest.title;
}

- (MWKTitle*)mostRecentSavedArticle {
    MWKSavedPageEntry* latest = [[self.savedPages entries] lastObject];
    return latest.title;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.dataSource = nil;

    [self flowLayout].estimatedItemHeight = 150;
    [self flowLayout].numberOfColumns     = 1;
    [self flowLayout].sectionInset        = UIEdgeInsetsMake(10.0, 8.0, 0.0, 8.0);
    [self flowLayout].minimumLineSpacing  = 10.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveWithNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
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

- (void)applicationDidBecomeActiveWithNotification:(NSNotification*)note {
    if (!self.isViewLoaded) {
        return;
    }

    //never loaded
    if ([self.dataSource numberOfSections] == 0) {
        return;
    }

    [self reloadRelatedArticlesForRecentArticles];
    [self reloadRelatedArticlesForSavedArticles];
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
        return [controller dequeueCellForCollectionView:self.collectionView atIndexPath:indexPath];
    };

    self.dataSource.cellConfigureBlock = ^(id cell, id object, id parentView, NSIndexPath* indexPath){
        @strongify(self);
        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
        [controller configureCell:cell withObject:object inCollectionView:parentView atIndexPath:indexPath];
    };

    self.dataSource.collectionSupplementaryCreationBlock = (id) ^ (NSString * kind, UICollectionView * cv, NSIndexPath * indexPath){
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            return (id)[WMFHomeSectionHeader supplementaryViewForCollectionView:cv kind:kind indexPath:indexPath];
        } else {
            return (id)[WMFHomeSectionFooter supplementaryViewForCollectionView:cv kind:kind indexPath:indexPath];
        }
    };

    self.dataSource.collectionSupplementaryConfigureBlock = ^(id view, NSString* kind, UICollectionView* cv, NSIndexPath* indexPath){
        @strongify(self);

        id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];

        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            WMFHomeSectionHeader* header     = view;
            NSMutableAttributedString* title = [[controller headerText] mutableCopy];
            [title addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:NSMakeRange(0, title.length)];
            [title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.353 green:0.353 blue:0.353 alpha:1] range:NSMakeRange(0, title.length)];
            header.titleView.attributedText = title;
            header.titleView.delegate       = self;
        } else {
            WMFHomeSectionFooter* footer = view;
            footer.moreLabel.text = controller.footerText;
        }
    };

    [self.collectionView registerNib:[WMFHomeSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFHomeSectionHeader wmf_nibName]];
    [self.collectionView registerNib:[WMFHomeSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFHomeSectionFooter wmf_nibName]];

    [self loadSectionForSectionController:self.recentSectionController];
    [self loadSectionForSectionController:self.nearbySectionController];
    [self loadSectionForSectionController:self.savedSectionController];

    self.dataSource.collectionView = self.collectionView;
}

#pragma mark - Section Management

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

    [controller registerCellsInCollectionView:self.collectionView];

    SSSection* section = [SSSection sectionWithItems:[controller items]];
    section.sectionIdentifier = controller.sectionIdentifier;

    [self.collectionView performBatchUpdates:^{
        [self.dataSource appendSection:section];
    } completion:NULL];
}

- (void)insertSectionForSectionController:(id<WMFHomeSectionController>)controller atIndex:(NSUInteger)index {
    if (!controller) {
        return;
    }
    self.sectionControllers[controller.sectionIdentifier] = controller;

    [controller registerCellsInCollectionView:self.collectionView];

    SSSection* section = [SSSection sectionWithItems:[controller items]];
    section.sectionIdentifier = controller.sectionIdentifier;

    [self.collectionView performBatchUpdates:^{
        [self.dataSource insertSection:section atIndex:index];
    } completion:NULL];
}

- (void)unloadSectionForSectionController:(id<WMFHomeSectionController>)controller {
    if (!controller) {
        return;
    }
    NSUInteger index = [self indexForSectionController:controller];

    [self.collectionView performBatchUpdates:^{
        [self.sectionControllers removeObjectForKey:controller.sectionIdentifier];
        [self.dataSource removeSectionAtIndex:index];
    } completion:NULL];
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section {
    return CGSizeMake([self contentWidth], 50.0);
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section {
    return CGSizeMake([self contentWidth], 80.0);
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    id object = [self.dataSource itemAtIndexPath:indexPath];

    id<WMFHomeSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    MWKTitle* title                         = [controller titleForItemAtIndex:indexPath.row];
    [self showArticleViewControllerForTitle:title animated:YES];
}

#pragma mark - Article Presentation

- (void)showArticleViewControllerForTitle:(MWKTitle*)title animated:(BOOL)animated {
    MWKArticle* article                                   = [self.dataStore articleWithTitle:title];
    WMFArticleContainerViewController* articleContainerVC = [WMFArticleContainerViewController articleContainerViewControllerWithDataStore:article.dataStore savedPages:self.savedPages];
    articleContainerVC.article = article;
    [self.navigationController pushViewController:articleContainerVC animated:animated];
}

#pragma mark - WMFHomeSectionControllerDelegate

- (void)controller:(id<WMFHomeSectionController>)controller didSetItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    [self.collectionView performBatchUpdates:^{
        [self.dataSource setItems:items inSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    [self.collectionView performBatchUpdates:^{
        [self.dataSource appendItems:items toSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller didUpdateItemsAtIndexes:(NSIndexSet*)indexes {
    NSInteger section = [self indexForSectionController:controller];
    [self.collectionView performBatchUpdates:^{
        [self.dataSource reloadCellsAtIndexes:indexes inSection:section];
    } completion:NULL];
}

- (void)controller:(id<WMFHomeSectionController>)controller enumerateVisibleCells:(WMFHomeSectionCellEnumerator)enumerator {
    NSInteger section = [self indexForSectionController:controller];

    [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL* stop) {
        if (obj.section == section) {
            enumerator([self.collectionView cellForItemAtIndexPath:obj], obj);
        }
    }];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)URL inRange:(NSRange)characterRange {
    MWKTitle* title = [[MWKTitle alloc] initWithURL:URL];
    [self showArticleViewControllerForTitle:title animated:YES];
    return NO;
}

@end


NS_ASSUME_NONNULL_END
