
#import "WMFHomeSectionController.h"
#import <SSDataSources/SSDataSources.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeSectionController ()

@property (nonatomic, weak, readwrite) SSSectionedDataSource* dataSource;

@end


@implementation WMFHomeSectionController

- (instancetype)initWithDataSource:(SSSectionedDataSource*)dataSource
{
    NSParameterAssert(dataSource);
    NSParameterAssert(dataSource.collectionView);

    self = [super init];
    if (self) {
        self.dataSource = dataSource;
    }
    return self;
}

- (UICollectionView*)collectionView{
    return self.dataSource.collectionView;
}

- (NSInteger)sectionIndex{
    return (NSInteger)[self.dataSource indexOfSectionWithIdentifier:self.sectionIdentifier];
}


- (SSSection*)section{
    return nil;
}

- (NSString*)sectionIdentifier{
    return nil;
}

- (NSString*)headerText{
    return nil;
}

- (NSString*)footerText{
    return nil;
}

- (void)registerCellsInCollectionView:(UICollectionView*)collectionView{
    
}


- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath{
    return nil;
}


- (void)configureCell:(UICollectionViewCell*)cell withObject:(id)object atIndexPath:(NSIndexPath*)indexPath{
    
}

@end

NS_ASSUME_NONNULL_END