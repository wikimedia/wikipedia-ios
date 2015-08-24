
#import "WMFHomeSectionFooter.h"

@implementation WMFHomeSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = NO;
    self.backgroundView.clipsToBounds = NO;
    self.backgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.backgroundView.layer.shadowOpacity = 0.15;
    self.backgroundView.layer.shadowRadius = 3.0;
    self.backgroundView.layer.shadowOffset = CGSizeZero;
}

- (void)setBounds:(CGRect)bounds{
    [super setBounds:bounds];
    self.backgroundView.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(self.backgroundView.bounds, -1.0, -1.0)].CGPath;
}

@end
