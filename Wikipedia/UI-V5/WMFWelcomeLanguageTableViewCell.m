
#import "WMFWelcomeLanguageTableViewCell.h"

@implementation WMFWelcomeLanguageTableViewCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.showsReorderControl = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //Remove indentation for delete control
    self.contentView.frame = CGRectMake(0,
                                        self.contentView.frame.origin.y,
                                        self.contentView.frame.size.width,
                                        self.contentView.frame.size.height);
}

@end
