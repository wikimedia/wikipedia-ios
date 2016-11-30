#import "WMFSelfSizingArticleListTableViewController.h"

@class MWKDataStore;
@class WMFArticleDataStore;
@class WMFRelatedSearchResults;

@interface WMFReadMoreViewController : WMFSelfSizingArticleListTableViewController

@property (nonatomic, strong, readonly) NSURL *articleURL;

- (instancetype)initWithURL:(NSURL *)url userStore:(MWKDataStore *)userDataStore previewStore:(WMFArticleDataStore *)previewStore;

- (void)fetchIfNeededWithCompletionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                            failureBlock:(void (^)(NSError *error))failure;

- (BOOL)hasResults;

@end
