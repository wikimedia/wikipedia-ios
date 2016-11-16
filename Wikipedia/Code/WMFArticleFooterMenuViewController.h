#import <UIKit/UIKit.h>
#import "WMFArticleListTableViewController.h"

@class MWKDataStore;
@class WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFooterMenuViewController : UIViewController

@property (nonatomic, strong, readonly) IBOutlet UITableView *tableView;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;

@property (nonatomic, strong, readonly) WMFArticleDataStore *previewStore;

@property (nonatomic, strong, readwrite) MWKArticle *article;

@property (nonatomic, weak, readonly) id<WMFArticleListTableViewControllerDelegate> similarPagesDelegate;

- (instancetype)initWithArticle:(MWKArticle *)article dataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore similarPagesListDelegate:(id<WMFArticleListTableViewControllerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
