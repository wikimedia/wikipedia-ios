#import "WMFCollectionViewLayout.h"

@interface WMFCollectionViewLayout ()
@property (nonatomic) CGSize previousBoundsSize;
@property (nonatomic) BOOL shouldInvalidate;
@end

@implementation WMFCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        self.previousBoundsSize = CGSizeZero;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    self.shouldInvalidate = newBounds.size.width != self.previousBoundsSize.width;
    self.previousBoundsSize = newBounds.size;
    return self.shouldInvalidate || [super shouldInvalidateLayoutForBoundsChange:newBounds];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    if (self.shouldInvalidate) {
        self.shouldInvalidate = NO;
        UICollectionViewFlowLayoutInvalidationContext *context = nil;
        if ([context isKindOfClass:[UICollectionViewFlowLayoutInvalidationContext class]]) {
            context = (UICollectionViewFlowLayoutInvalidationContext *)context;
        } else {
            context = [[UICollectionViewFlowLayoutInvalidationContext alloc] init];
        }
        context.invalidateFlowLayoutDelegateMetrics = NO;
        context.invalidateFlowLayoutAttributes = YES;
        self.estimatedItemSize = CGSizeMake(self.previousBoundsSize.width, 50);
        [super invalidateLayoutWithContext:context];
    } else {
        [super invalidateLayoutWithContext:context];
    }
}

@end
