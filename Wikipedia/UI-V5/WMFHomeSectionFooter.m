
#import "WMFHomeSectionFooter.h"
#import "UIView+WMFShadow.h"

@implementation WMFHomeSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = NO;
    [self.backgroundView wmf_setupShadow];
}

@end
