
#import "WMFHomeSectionFooter.h"
#import "UIView+WMFShadow.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation WMFHomeSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = NO;
    //[self.backgroundView wmf_setupShadow];
    @weakify(self);
    [self bk_whenTapped:^{
        @strongify(self);
        if (self.whenTapped) {
            self.whenTapped();
        }
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.moreLabel.text = nil;
    self.whenTapped     = nil;
}

@end
