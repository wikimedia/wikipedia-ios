
#import "WMFExploreSectionFooter.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation WMFExploreSectionFooter

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
