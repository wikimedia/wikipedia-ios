
#import "WMFLocationSearchListViewController.h"
#import "WMFNearbyArticleTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLocationSearchResult.h"

@interface WMFLocationSearchListViewController ()

@end

@implementation WMFLocationSearchListViewController

@dynamic dataSource;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = MWLocalizedString(@"main-menu-nearby", nil);

    [self.tableView registerNib:[WMFNearbyArticleTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFNearbyArticleTableViewCell identifier]];
}

- (void)setDataSource:(WMFNearbyTitleListDataSource*)dataSource {
    dataSource.cellClass = [WMFNearbyArticleTableViewCell class];

    @weakify(self);
    dataSource.cellConfigureBlock = ^(WMFNearbyArticleTableViewCell* nearbyCell,
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

    [super setDataSource:dataSource];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

- (NSString*)analyticsName {
    return @"Nearby";
}

@end
