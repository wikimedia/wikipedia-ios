#import "WMFSelfSizingArticleListTableViewController.h"

@class MWKDataStore;
@class WMFRelatedSearchResults;

@interface WMFReadMoreViewController : WMFSelfSizingArticleListTableViewController

@property (nonatomic, strong, readonly) NSURL *articleURL;

- (instancetype)initWithURL:(NSURL *)url userStore:(MWKDataStore *)userDataStore;

- (void)fetchIfNeededWithCompletionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                            failureBlock:(void (^)(NSError *error))failure;

- (BOOL)hasResults;

@end
