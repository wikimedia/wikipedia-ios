
#import "WMFLocationSearchListViewController.h"
#import "WMFNearbyArticleTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLocationSearchResult.h"
#import "MWKSite.h"

@interface WMFLocationSearchListViewController ()
@property (nonatomic, strong) WMFNearbyTitleListDataSource* dataSource;
@property (nonatomic, strong, readwrite) MWKSite* site;
@end

@implementation WMFLocationSearchListViewController

@dynamic dataSource;

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(site);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.site                 = site;
        self.dataStore            = dataStore;
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
            [nearbyCell setDistanceProvider:[self.dataSource distanceProviderForResultAtIndexPath:indexPath]];
            [nearbyCell setBearingProvider:[self.dataSource bearingProviderForResultAtIndexPath:indexPath]];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = MWLocalizedString(@"main-menu-nearby", nil);
    [self.tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (NSString*)analyticsName {
    return @"Nearby";
}

@end
