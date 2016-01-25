
#import "WMFLocationSearchListViewController.h"
#import "WMFCompassViewModel.h"
#import "WMFNearbyArticleTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLocationSearchResult.h"
#import "MWKSite.h"

@interface WMFLocationSearchListViewController ()
@property (nonatomic, strong) WMFNearbyTitleListDataSource* dataSource;
@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong) WMFCompassViewModel* compassViewModel;
@end

@implementation WMFLocationSearchListViewController

@dynamic dataSource;

- (instancetype)initWithLocation:(CLLocation*)location searchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(location);
    self = [self initWithSearchSite:site dataStore:dataStore];
    if (self) {
        self.location = location;
    }
    return self;
}

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.site                 = site;
        self.dataStore            = dataStore;
        self.compassViewModel     = [[WMFCompassViewModel alloc] init];
        self.dataSource           = [[WMFNearbyTitleListDataSource alloc] initWithSite:self.site];
        self.dataSource.cellClass = [WMFNearbyArticleTableViewCell class];

        @weakify(self);
        self.dataSource.cellConfigureBlock = ^(WMFNearbyArticleTableViewCell* nearbyCell,
                                               MWKLocationSearchResult* result,
                                               UITableView* tableView,
                                               NSIndexPath* indexPath) {
            @strongify(self);
            nearbyCell.titleText       = result.displayTitle;
            nearbyCell.descriptionText = result.wikidataDescription;
            [nearbyCell setImageURL:result.thumbnailURL];
            [nearbyCell setDistanceProvider:[self.compassViewModel distanceProviderForResult:result]];
            [nearbyCell setBearingProvider:[self.compassViewModel bearingProviderForResult:result]];
        };
    }
    return self;
}

- (void)setLocation:(CLLocation*)location {
    self.dataSource.location = location;
}

- (CLLocation*)location {
    return self.dataSource.location;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = MWLocalizedString(@"main-menu-nearby", nil);
    [self.tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.compassViewModel startUpdates];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.compassViewModel stopUpdates];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (NSString*)analyticsName {
    return @"Nearby";
}

@end
