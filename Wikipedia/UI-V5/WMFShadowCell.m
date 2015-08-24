

#import "WMFShadowCell.h"

@implementation WMFShadowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds                   = NO;
    self.contentView.clipsToBounds       = NO;
    self.contentView.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOpacity = 0.15;
    self.contentView.layer.shadowRadius  = 3.0;
    self.contentView.layer.shadowOffset  = CGSizeZero;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, -1.0, -1.0)].CGPath;
}

@end
