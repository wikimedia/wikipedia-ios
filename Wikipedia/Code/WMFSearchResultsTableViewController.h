#import "WMFArticleListTableViewController.h"

@class WMFSearchResults;

@interface WMFSearchResultsTableViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property (nonatomic, strong, readwrite) WMFSearchResults *searchResults;

- (BOOL)isDisplayingResultsForSearchTerm:(NSString *)searchTerm fromSiteURL:(NSURL *)siteURL;

@end
