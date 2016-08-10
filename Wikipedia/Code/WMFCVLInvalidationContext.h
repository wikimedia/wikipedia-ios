#import <UIKit/UIKit.h>

@interface WMFCVLInvalidationContext : UICollectionViewLayoutInvalidationContext

@property (nonatomic, copy) UICollectionViewLayoutAttributes *originalLayoutAttributes;
@property (nonatomic, copy) UICollectionViewLayoutAttributes *preferredLayoutAttributes;

@property (nonatomic) BOOL sizeDidChange;
@property (nonatomic) CGSize size;

@end
