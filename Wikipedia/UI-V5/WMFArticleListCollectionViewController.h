
#import <UIKit/UIKit.h>
#import "WMFArticleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleListMode) {
    WMFArticleListModeNormal = 0,
    WMFArticleListModeBottomStacked
};

@interface WMFArticleListCollectionViewController : UICollectionViewController

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong, nullable) id<WMFArticleListDataSource> dataSource;

@property (nonatomic, assign, readonly) WMFArticleListMode mode;

- (void)setListMode:(WMFArticleListMode)mode animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)refreshVisibleCells;

@end


NS_ASSUME_NONNULL_END