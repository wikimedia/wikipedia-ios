
#import "WMFExploreSectionHeader.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@interface WMFExploreSectionHeader ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* rightButtonWidthConstraint;
@property (assign, nonatomic) CGFloat rightButtonWidthConstraintConstant;

@end

@implementation WMFExploreSectionHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tintColor                          = [UIColor wmf_blueTintColor];
    self.rightButtonWidthConstraintConstant = self.rightButtonWidthConstraint.constant;
    self.rightButton.hidden                 = YES;
    self.rightButton.tintColor              = [UIColor wmf_blueTintColor];
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
    self.rightButtonEnabled = NO;
}

- (void)setRightButtonEnabled:(BOOL)rightButtonEnabled {
    if (_rightButtonEnabled == rightButtonEnabled) {
        return;
    }
    _rightButtonEnabled     = rightButtonEnabled;
    self.rightButton.hidden = !self.rightButtonEnabled;
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)updateConstraints {
    if (self.rightButtonEnabled) {
        self.rightButtonWidthConstraint.constant = self.rightButtonWidthConstraintConstant;
    } else {
        self.rightButtonWidthConstraint.constant = 0;
    }
    [super updateConstraints];
}

@end
