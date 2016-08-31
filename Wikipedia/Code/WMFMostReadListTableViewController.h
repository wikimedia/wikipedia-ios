#import "WMFArticleListTableViewController.h"
#import "WMFAnalyticsLogging.h"

@class WMFExploreSection;
@class WMFArticlePreviewDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadListTableViewController : WMFArticleListTableViewController<WMFAnalyticsContextProviding>

- (instancetype)initWithSection:(WMFExploreSection*)section articleURLs:(NSArray<NSURL*>*)urls userDataStore:(MWKDataStore*)userDataStore previewStore:(WMFArticlePreviewDataStore*)previewStore NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong, readonly) WMFExploreSection* section;
@property (nonatomic, strong, readonly) NSArray<NSURL*>* articleURLs;


- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
