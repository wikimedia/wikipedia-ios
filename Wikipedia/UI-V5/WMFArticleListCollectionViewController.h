
#import <UIKit/UIKit.h>
#import "WMFArticleListDataSource.h"
@class SSArrayDataSource;

@class MWKDataStore, MWKSavedPageList, MWKHistoryList, SelfSizingWaterfallCollectionViewLayout;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleListMode) {
    WMFArticleListModeNormal = 0,
    WMFArticleListModeOffScreen
};

@interface WMFArticleListCollectionViewController : UICollectionViewController

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKHistoryList* recentPages;
@property (nonatomic, strong, nullable) SSArrayDataSource<WMFArticleListDataSource>* dataSource;

- (SelfSizingWaterfallCollectionViewLayout*)flowLayout;

- (void)refreshVisibleCells;

- (void)scrollToArticle:(MWKArticle*)article animated:(BOOL)animated;

- (void)scrollToArticleIfOffscreen:(MWKArticle*)article animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
