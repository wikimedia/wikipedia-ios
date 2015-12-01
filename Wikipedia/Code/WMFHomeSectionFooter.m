
#import "WMFHomeSectionFooter.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation WMFHomeSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = NO;
    @weakify(self);
    [self bk_whenTapped:^{
        @strongify(self);
        if (self.whenTapped) {
            self.whenTapped();
        }
    }];
}

@end
