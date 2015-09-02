

#import "WMFShadowCell.h"
#import "UIView+WMFShadow.h"

@implementation WMFShadowCell

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds               = NO;
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentView wmf_setupShadow];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.contentView wmf_setupShadow];
}

@end
