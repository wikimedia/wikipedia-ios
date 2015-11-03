
#import <UIKit/UIKit.h>
#import "WMFTitleListDataSource.h"
#import "WMFArticleSelectionDelegate.h"

@class SSBaseDataSource;

@class MWKDataStore, MWKSavedPageList, MWKHistoryList, SelfSizingWaterfallCollectionViewLayout;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleListMode) {
    WMFArticleListModeNormal = 0,
    WMFArticleListModeOffScreen
};

@interface WMFArticleListCollectionViewController : UIViewController

@property (nonatomic, strong, readonly) UICollectionView* collectionView;

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong, nullable) SSBaseDataSource<WMFTitleListDataSource>* dataSource;

/**
 *  Optional delegate which will is informed of selection.
 *
 *  If left @c nil, falls back to pushing an article container using its @c navigationController.
 */
@property (nonatomic, weak, nullable) id<WMFArticleSelectionDelegate> delegate;

- (SelfSizingWaterfallCollectionViewLayout*)flowLayout;

@end

// TODO: move to separate file in article container folder
@interface WMFSelfSizingArticleListCollectionViewController : WMFArticleListCollectionViewController

@end

NS_ASSUME_NONNULL_END
