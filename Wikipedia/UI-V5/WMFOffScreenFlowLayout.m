
#import "WMFOffScreenFlowLayout.h"

@implementation WMFOffScreenFlowLayout


#pragma mark - Setup

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefualts];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefualts];
    }
    return self;
}

- (void)setupDefualts {
    self.minimumLineSpacing      = 0.0f;
    self.minimumInteritemSpacing = 0.0f;
    self.scrollDirection         = UICollectionViewScrollDirectionVertical;
}

#pragma mark - UICollectionViewLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* items = [super layoutAttributesForElementsInRect:rect];

    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [self adjustLayoutAttributes:obj];
    }];

    return items;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* item = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self adjustLayoutAttributes:item];
    return item;
}

- (void)adjustLayoutAttributes:(UICollectionViewLayoutAttributes*)attributes {
    CGRect frame = attributes.frame;
    frame.origin.y    = CGRectGetHeight(self.collectionView.bounds);
    attributes.frame  = frame;
    attributes.zIndex = attributes.indexPath.item;
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.bounds.size;
}

@end
