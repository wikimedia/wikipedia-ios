
#import <UIKit/UIKit.h>
#import "WMFArticleListDataSource.h"
#import "WMFArticleListTranstion.h"

@class MWKDataStore, MWKSavedPageList, MWKHistoryList;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleListMode) {
    WMFArticleListModeNormal = 0,
    WMFArticleListModeOffScreen
};

@interface WMFArticleListCollectionViewController : UICollectionViewController<WMFArticleListTranstioning>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKHistoryList* recentPages;
@property (nonatomic, strong, nullable) id<WMFArticleListDataSource> dataSource;

@property (nonatomic, assign, readonly) WMFArticleListMode mode;

- (void)setListMode:(WMFArticleListMode)mode animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)refreshVisibleCells;

- (void)scrollToArticle:(MWKArticle*)article animated:(BOOL)animated;

- (void)scrollToArticleIfOffscreen:(MWKArticle*)article animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
