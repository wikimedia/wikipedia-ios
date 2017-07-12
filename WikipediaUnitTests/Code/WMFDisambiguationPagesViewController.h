#import "WMFArticleListDataSourceTableViewController.h"

@interface WMFDisambiguationPagesViewController : WMFArticleListDataSourceTableViewController

@property (nonatomic, strong, readonly) NSArray *URLs;
@property (nonatomic, strong, readonly) NSURL *siteURL;

- (instancetype)initWithURLs:(NSArray *)URLs siteURL:(NSURL*)siteURL dataStore:(MWKDataStore *)dataStore;

@end
