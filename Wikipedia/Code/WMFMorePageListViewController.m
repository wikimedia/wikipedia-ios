#import "WMFMorePageListViewController.h"

#import "WMFLocationManager.h"
#import "CLLocation+WMFBearing.h"

#import "WMFContentGroup+WMFFeedContentDisplaying.m"

#import "WMFArticleListTableViewCell.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "WMFNearbyArticleTableViewCell.h"

#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMorePageListViewController () <WMFLocationManagerDelegate>

@property (nonatomic, strong) WMFLocationManager *locationManager;

@property (nonatomic, strong, readwrite) WMFContentGroup *group;
@property (nonatomic, strong, readwrite) NSArray<NSURL *> *articleURLs;

@end

@implementation WMFMorePageListViewController

- (instancetype)initWithGroup:(WMFContentGroup *)group articleURLs:(NSArray<NSURL *> *)urls userDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(urls);
    NSParameterAssert(group);
    NSParameterAssert(userDataStore);
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.userDataStore = userDataStore;
        self.group = group;
        self.articleURLs = urls;
    }
    return self;
}

#pragma mark - Accessors

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

- (void)setCellType:(WMFMorePageListCellType)cellType {
    _cellType = cellType;
    if ([self isViewLoaded]) {
        [self registerCells];
    }
}

- (WMFLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [WMFLocationManager fineLocationManager];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.group moreTitle];
    [self registerCells];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.cellType == WMFMorePageListCellTypeLocation) {
        [self.locationManager startMonitoringLocation];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.locationManager stopMonitoringLocation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.articleURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.cellType) {
        case WMFMorePageListCellTypeNormal: {
            return [self listCellForRowAtIndexPath:indexPath];
        } break;
        case WMFMorePageListCellTypePreview: {
            return [self previewCellForRowAtIndexPath:indexPath];
        } break;
        case WMFMorePageListCellTypeLocation: {
            return [self locationCellForRowAtIndexPath:indexPath];
        } break;

        default:
            NSAssert(false, @"Unknown Cell Type");
            return nil;
            break;
    }
}

#pragma mark - Cells

- (void)registerCells {
    switch (self.cellType) {
        case WMFMorePageListCellTypeNormal: {
            [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib]
                 forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
            self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];
            [self.locationManager stopMonitoringLocation];
        } break;
        case WMFMorePageListCellTypePreview: {
            [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
            self.tableView.estimatedRowHeight = [WMFArticlePreviewTableViewCell estimatedRowHeight];
            [self.locationManager stopMonitoringLocation];
        } break;
        case WMFMorePageListCellTypeLocation: {
            [self.tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
            self.tableView.estimatedRowHeight = [WMFNearbyArticleTableViewCell estimatedRowHeight];
        } break;
        default:
            NSAssert(false, @"Unknown Cell Type");
            break;
    }
    [self.tableView reloadData];
}

- (WMFArticleListTableViewCell *)listCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];

    NSURL *url = self.articleURLs[indexPath.row];
    WMFArticle *preview = [self.userDataStore fetchArticleWithURL:url];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = preview.capitalizedWikidataDescription;
    [cell setImageURL:preview.thumbnailURL];
    return cell;
}

- (WMFArticlePreviewTableViewCell *)previewCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticlePreviewTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticlePreviewTableViewCell identifier] forIndexPath:indexPath];

    NSURL *url = self.articleURLs[indexPath.row];
    WMFArticle *preview = [self.userDataStore fetchArticleWithURL:url];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = preview.capitalizedWikidataDescription;
    cell.snippetText = preview.snippet;
    [cell setImageURL:preview.thumbnailURL];
    cell.saveButtonController.analyticsContext = [self analyticsContext];
    [cell setSaveableURL:url savedPageList:self.userDataStore.savedPageList];

    return cell;
}

- (WMFNearbyArticleTableViewCell *)locationCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    WMFNearbyArticleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFNearbyArticleTableViewCell wmf_nibName] forIndexPath:indexPath];

    NSURL *url = self.articleURLs[indexPath.row];
    WMFArticle *preview = [self.userDataStore fetchArticleWithURL:url];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = preview.capitalizedWikidataDescription;
    [cell setImageURL:preview.thumbnailURL];
    [self updateLocationCell:cell location:preview.location];

    return cell;
}

#pragma mark - Location Updates

- (void)updateLocationCells {
    [[self.tableView indexPathsForVisibleRows] enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        WMFNearbyArticleTableViewCell *cell = [self.tableView cellForRowAtIndexPath:obj];
        NSURL *url = self.articleURLs[obj.row];
        WMFArticle *preview = [self.userDataStore fetchArticleWithURL:url];
        [self updateLocationCell:cell location:preview.location];
    }];
}
- (void)updateLocationCell:(WMFNearbyArticleTableViewCell *)cell location:(CLLocation *)location {
    CLLocation *userLocation = self.locationManager.location;
    if (userLocation == nil) {
        [cell configureForUnknownDistance];
        return;
    }
    [cell setDistance:[userLocation distanceFromLocation:location]];
    [cell setBearing:[userLocation wmf_bearingToLocation:location forCurrentHeading:self.locationManager.heading]];
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

#pragma mark - WMFArticleListViewController

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNone;
}

- (NSInteger)numberOfItems {
    return [self.articleURLs count];
}

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath {
    return self.articleURLs[indexPath.row];
}

#pragma mark - Analytics

- (NSString *)analyticsContext {
    return [@"More " stringByAppendingString:self.group.analyticsContentType];
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

@end

NS_ASSUME_NONNULL_END
