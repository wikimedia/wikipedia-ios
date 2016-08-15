#import "WMFArticleListTableViewController.h"

@class MWKSearchResult;

@interface WMFMostReadListTableViewController : WMFArticleListTableViewController

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult *> *)previews
                     fromSiteURL:(NSURL *)siteURL
                         forDate:date
                       dataStore:(MWKDataStore *)dataStore;

@end
