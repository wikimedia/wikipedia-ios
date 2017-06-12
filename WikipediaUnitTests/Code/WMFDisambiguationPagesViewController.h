#import "WMFArticleListDataSourceTableViewController.h"
@class MWKArticle;

@interface WMFDisambiguationPagesViewController : WMFArticleListDataSourceTableViewController

@property (nonatomic, strong, readonly) MWKArticle *article;

- (instancetype)initWithArticle:(MWKArticle *)article dataStore:(MWKDataStore *)dataStore;

@end
