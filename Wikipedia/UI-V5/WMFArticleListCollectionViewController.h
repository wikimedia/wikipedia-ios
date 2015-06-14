
#import <UIKit/UIKit.h>

@protocol WMFArticleListDataSource <NSObject>

- (NSString*)displayTitle;

- (NSUInteger) articleCount;
- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath;

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath;
- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath;

@end


@interface WMFArticleListCollectionViewController : UICollectionViewController

@property (nonatomic, strong) id<WMFArticleListDataSource> dataSource;


@end
