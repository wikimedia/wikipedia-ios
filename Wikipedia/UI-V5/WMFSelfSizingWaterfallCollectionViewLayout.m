
#import "WMFSelfSizingWaterfallCollectionViewLayout.h"

@implementation WMFSelfSizingWaterfallCollectionViewLayout

- (CGSize)collectionViewContentSize {
    if ([self.collectionView numberOfSections] == 1 && [self.collectionView numberOfItemsInSection:0] == 0) {
        return self.collectionView.bounds.size;
    }

    return [super collectionViewContentSize];
}

@end
