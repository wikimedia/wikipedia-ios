#import "WMFArticleListTableViewController.h"

@interface WMFDisambiguationPagesViewController : WMFArticleListTableViewController

@property (nonatomic, strong, readonly) MWKArticle* article;

- (instancetype)initWithArticle:(MWKArticle*)article dataStore:(MWKDataStore*)dataStore;

@end
