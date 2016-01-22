#import "WMFArticleListTableViewController.h"

@interface WMFTrendingViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) NSDate* date;

- (instancetype)initWithSite:(MWKSite*)site date:(NSDate*)date dataStore:(MWKDataStore*)dataStore;

@end
