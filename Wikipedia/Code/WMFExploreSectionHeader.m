#import "WMFExploreSectionHeader.h"
#import "BlocksKit+UIKit.h"

@interface WMFExploreSectionHeader ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightButtonWidthConstraint;
@property (assign, nonatomic) CGFloat rightButtonWidthConstraintConstant;

@property (strong, nonatomic) IBOutlet UIImageView *icon;
@property (strong, nonatomic) IBOutlet UIView *iconContainerView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;

@end

@implementation WMFExploreSectionHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    [self reset];
    self.titleLabel.isAccessibilityElement = NO;
    self.subTitleLabel.isAccessibilityElement = NO;
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitHeader;
    self.tintColor = [UIColor wmf_blueTintColor];
    self.rightButtonWidthConstraintConstant = self.rightButtonWidthConstraint.constant;
    self.rightButton.hidden = YES;
    self.rightButton.tintColor = [UIColor wmf_blueTintColor];
    @weakify(self);
    [self bk_whenTapped:^{
        @strongify(self);
        if (self.whenTapped) {
            self.whenTapped();
        }
    }];
}

- (void)setImage:(UIImage *)image {
    self.icon.image = image;
}

- (void)setImageTintColor:(UIColor *)imageTintColor {
    self.icon.tintColor = imageTintColor;
}

- (void)setImageBackgroundColor:(UIColor *)imageBackgroundColor {
    self.iconContainerView.backgroundColor = imageBackgroundColor;
}

- (void)setTitle:(NSAttributedString *)title {
    self.titleLabel.attributedText = title;
    [self updateAccessibilityLabel];
}

- (void)setSubTitle:(NSAttributedString *)subTitle {
    self.subTitleLabel.attributedText = subTitle;
    [self updateAccessibilityLabel];
}

- (void)updateAccessibilityLabel {
    NSString *title = self.titleLabel.text;
    NSString *subtitle = self.subTitleLabel.text;
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:2];
    if (title) {
        [components addObject:title];
    }
    if (subtitle) {
        [components addObject:subtitle];
    }
    self.accessibilityLabel = [components componentsJoinedByString:@" "];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self reset];
}

- (void)reset {
    self.titleLabel.text = @"";
    self.subTitleLabel.text = @"";
    self.rightButtonEnabled = NO;
}

- (void)setRightButtonEnabled:(BOOL)rightButtonEnabled {
    if (_rightButtonEnabled == rightButtonEnabled) {
        return;
    }
    _rightButtonEnabled = rightButtonEnabled;
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
