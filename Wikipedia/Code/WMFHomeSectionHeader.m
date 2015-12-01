
#import "WMFHomeSectionHeader.h"

@interface WMFHomeSectionHeader ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* rightButtonWidthConstraint;
@property (assign, nonatomic) CGFloat rightButtonWidthConstraintConstant;

@end

@implementation WMFHomeSectionHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tintColor                          = [UIColor wmf_logoBlue];
    self.rightButtonWidthConstraintConstant = self.rightButtonWidthConstraint.constant;
}

- (void)setRightButtonEnabled:(BOOL)rightButtonEnabled {
    _rightButtonEnabled = rightButtonEnabled;
    if (rightButtonEnabled) {
        self.rightButtonWidthConstraint.constant = self.rightButtonWidthConstraintConstant;
        self.rightButton.hidden                  = NO;
    } else {
        self.rightButtonWidthConstraint.constant = 0;
        self.rightButton.hidden                  = YES;
    }
}

@end
