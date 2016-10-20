#import "WMFArticleListTableViewController.h"

@class WMFContentGroup;
@class WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFMorePageListCellType) {
    WMFMorePageListCellTypeNormal,
    WMFMorePageListCellTypePreview,
    WMFMorePageListCellTypeLocation
};

@interface WMFMorePageListViewController : WMFArticleListTableViewController

- (instancetype)initWithGroup:(WMFContentGroup *)section articleURLs:(NSArray<NSURL *> *)urls userDataStore:(MWKDataStore *)userDataStore previewStore:(WMFArticlePreviewDataStore *)previewStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) WMFMorePageListCellType cellType;

@property (nonatomic, strong, readonly) WMFContentGroup *group;
@property (nonatomic, strong, readonly) NSArray<NSURL *> *articleURLs;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
