
#import "WMFSelfSizingArticleListTableViewController.h"

@interface WMFReadMoreViewController : WMFSelfSizingArticleListTableViewController

@property (nonatomic, strong, readonly) MWKTitle* articleTitle;

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore;

- (AnyPromise*)fetch;

- (BOOL)hasResults;

@end
