#import "WMFSelfSizingArticleListTableViewController.h"

@class MWKDataStore;
@class WMFArticlePreviewDataStore;
@class WMFRelatedSearchResults;

@interface WMFReadMoreViewController : WMFSelfSizingArticleListTableViewController

@property (nonatomic, strong, readonly) NSURL *articleURL;

- (instancetype)initWithURL:(NSURL *)url userStore:(MWKDataStore *)userDataStore previewStore:(WMFArticlePreviewDataStore *)previewStore;

- (void)fetchIfNeededWithCompletionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                            failureBlock:(void (^)(NSError *error))failure;

- (BOOL)hasResults;

@end
