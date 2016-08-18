#import "WMFArticleListDataSourceTableViewController.h"

@class MWKSearchResult;

@interface WMFMostReadListTableViewController : WMFArticleListDataSourceTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews
                     fromSiteURL:(NSURL*)siteURL
                         forDate:date
                       dataStore:(MWKDataStore*)dataStore;

@end
