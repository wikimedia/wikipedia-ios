
#import "WMFHomeSectionFooter.h"
#import "UIView+WMFShadow.h"

@implementation WMFHomeSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = NO;
    [self.backgroundView wmf_setupShadow];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self.backgroundView wmf_updateShadowPathBasedOnBounds];
}

@end
