#import "WMFArticleListDataSourceTableViewController.h"

@interface WMFDisambiguationPagesViewController : WMFArticleListDataSourceTableViewController

@property (nonatomic, strong, readonly) MWKArticle* article;

- (instancetype)initWithArticle:(MWKArticle*)article dataStore:(MWKDataStore*)dataStore;

@end
