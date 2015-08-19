
#import <Foundation/Foundation.h>

@class SSSectionedDataSource;

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeSectionController : NSObject

- (instancetype)initWithDataSource:(SSSectionedDataSource*)dataSource;

@property (nonatomic, weak, readonly) SSSectionedDataSource* dataSource;

- (NSInteger)sectionIndex;

- (UICollectionView*)collectionView;

- (NSString*)sectionIdentifier;

- (NSString*)headerText;

- (NSString*)footerText;

- (void)registerCellsInCollectionView:(UICollectionView*)collectionView;

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath;

- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END