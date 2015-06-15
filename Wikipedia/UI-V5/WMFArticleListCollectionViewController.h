
#import <UIKit/UIKit.h>

@protocol WMFArticleListDataSource <NSObject>

- (NSString*)displayTitle;

- (NSUInteger) articleCount;
- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;
- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

@end

typedef NS_ENUM(NSUInteger, WMFArticleListMode) {
    
    WMFArticleListModeNormal = 0,
    WMFArticleListModeBottomStacked
};

@interface WMFArticleListCollectionViewController : UICollectionViewController

@property (nonatomic, strong) id<WMFArticleListDataSource> dataSource;

@property (nonatomic, assign, readonly) WMFArticleListMode mode;

- (void)setListMode:(WMFArticleListMode)mode animated:(BOOL)animated;

@end
