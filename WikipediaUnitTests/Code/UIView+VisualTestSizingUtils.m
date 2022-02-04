#import "UIView+VisualTestSizingUtils.h"

@implementation UIView (VisualTestSizingUtils)

- (CGRect)wmf_sizeThatFitsWidth:(CGFloat)width {
    CGSize sizeThatFitsWidth = [self systemLayoutSizeFittingSize:CGSizeMake(width, UIViewNoIntrinsicMetric)
                                   withHorizontalFittingPriority:UILayoutPriorityRequired
                                         verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    return (CGRect){
        .origin = CGPointZero,
        .size = CGSizeMake(floor(width), floor(sizeThatFitsWidth.height))};
}

- (void)wmf_sizeToFitWidth:(CGFloat)width {
    self.frame = [self wmf_sizeThatFitsWidth:width];
}

@end

@interface UICollectionViewCell (VisualTestSizingUtils)

@end

@implementation UICollectionViewCell (VisualTestSizingUtils)

- (void)wmf_sizeToFitWidth:(CGFloat)width {
    [super wmf_sizeToFitWidth:width];
    self.contentView.frame = self.frame;
}

@end

@interface UITableViewCell (VisualTestSizingUtils)

@end

@implementation UITableViewCell (VisualTestSizingUtils)

- (void)wmf_sizeToFitWidth:(CGFloat)width {
    [super wmf_sizeToFitWidth:width];
    self.contentView.frame = self.frame;
}

@end
