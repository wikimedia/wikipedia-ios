

#import "WMFHomeViewController.h"

#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"

#import "WMFNearbySectionController.h"
#import "WMFSettingsViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

#import <SSDataSources/SSDataSources.h>
#import "SSSectionedDataSource+WMFSectionConvenience.h"

#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"

#import "MWKSite.h"
#import "MWKLocationSearchResult.h"
#import "MWKTitle.h"
#import "MWKArticle.h"

#import <SelfSizingWaterfallCollectionViewLayout/SelfSizingWaterfallCollectionViewLayout.h>

#import "UIView+WMFDefaultNib.h"
#import "WMFHomeSectionHeader.h"
#import "WMFHomeSectionFooter.h"

#import "WMFArticleContainerViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeViewController ()<WMFHomeSectionControllerDelegate>

@property (nonatomic, strong) WMFNearbySectionController* nearbySectionController;

@property (nonatomic, strong) WMFLocationManager* locationManager;
@property (nonatomic, strong) WMFLocationSearchFetcher* locationSearchFetcher;
@property (nonatomic, strong) SSSectionedDataSource* dataSource;

@property (nonatomic, strong) NSMutableDictionary* sectionControllers;

@end

@implementation WMFHomeViewController

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

- (WMFNearbySectionController*)nearbySectionController {
    if (!_nearbySectionController) {
        _nearbySectionController          = [[WMFNearbySectionController alloc] initWithLocationManager:self.locationManager locationSearchFetcher:self.locationSearchFetcher];
        _nearbySectionController.delegate = self;
    }
    return _nearbySectionController;
}

- (WMFLocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [[WMFLocationManager alloc] init];
    }
    return _locationManager;
}

- (WMFLocationSearchFetcher*)locationSearchFetcher {
    if (!_locationSearchFetcher) {
        _locationSearchFetcher = [[WMFLocationSearchFetcher alloc] initWithSearchSite:self.searchSite];
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

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.dataSource = nil;

    CGFloat width = self.view.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
    [self flowLayout].estimatedItemHeight = 150;
    [self flowLayout].numberOfColumns     = 1;
    [self flowLayout].headerReferenceSize = CGSizeMake(width, 50.0);
    [self flowLayout].footerReferenceSize = CGSizeMake(width, 50.0);
    [self flowLayout].sectionInset        = UIEdgeInsetsMake(10.0, 8.0, 10.0, 8.0);
    [self flowLayout].minimumLineSpacing  = 10.0;
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

- (id<WMFHomeSectionController>)sectionControllerForSectionAtIndex:(NSInteger)index {
    SSSection* section = [self.dataSource sectionAtIndex:index];
    return self.sectionControllers[section.sectionIdentifier];
}

- (NSInteger)indexForSectionController:(id<WMFHomeSectionController>)controller {
    return (NSInteger)[self.dataSource indexOfSectionWithIdentifier:[controller sectionIdentifier]];
}

#pragma mark - Data Source Configuration

- (void)configureDataSource {
    if (_dataSource != nil) {
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
            WMFHomeSectionHeader* header = view;
            header.titleLabel.text = controller.headerText;
        } else {
            WMFHomeSectionFooter* footer = view;
            footer.moreLabel.text = controller.footerText;
        }
    };

    [self.collectionView registerNib:[WMFHomeSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFHomeSectionHeader wmf_nibName]];
    [self.collectionView registerNib:[WMFHomeSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFHomeSectionFooter wmf_nibName]];

    [self loadSectionForSectionController:self.nearbySectionController];
    self.dataSource.collectionView = self.collectionView;
}

- (void)loadSectionForSectionController:(id<WMFHomeSectionController>)controller {
    self.sectionControllers[controller.sectionIdentifier] = controller;

    [controller registerCellsInCollectionView:self.collectionView];

    SSSection* section = [SSSection sectionWithItems:[controller items]];
    section.sectionIdentifier = controller.sectionIdentifier;

    [self.collectionView performBatchUpdates:^{
        [self.dataSource appendSection:section];
    } completion:NULL];
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section {
    CGFloat width = self.view.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
    return CGSizeMake(width, 50.0);
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section {
    CGFloat width = self.view.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
    return CGSizeMake(width, 50.0);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    id object = [self.dataSource itemAtIndexPath:indexPath];

    //TODO: Casting for now - ned to make a protocol or something
    MWKLocationSearchResult* result = object;
    MWKTitle* title                 = [[MWKSite siteWithCurrentLocale] titleWithString:result.displayTitle];
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
    } completion:^(BOOL finished) {
    }];
}

- (void)controller:(id<WMFHomeSectionController>)controller didAppendItems:(NSArray*)items {
    NSInteger section = [self indexForSectionController:controller];
    [self.collectionView performBatchUpdates:^{
        [self.dataSource appendItems:items toSection:section];
    } completion:^(BOOL finished) {
    }];
}

- (void)controller:(id<WMFHomeSectionController>)controller enumerateVisibleCells:(WMFHomeSectionCellEnumerator)enumerator {
    NSInteger section = [self indexForSectionController:controller];

    [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath* obj, NSUInteger idx, BOOL* stop) {
        if (obj.section == section) {
            enumerator([self.collectionView cellForItemAtIndexPath:obj], obj);
        }
    }];
}

@end


NS_ASSUME_NONNULL_END
