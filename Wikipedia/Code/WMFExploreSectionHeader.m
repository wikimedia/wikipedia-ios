#import "WMFExploreSectionHeader.h"
#import "BlocksKit+UIKit.h"
#import "Wikipedia-Swift.h"

@interface WMFExploreSectionHeader ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightButtonWidthConstraint;
@property (assign, nonatomic) CGFloat rightButtonWidthConstraintConstant;

@property (strong, nonatomic) IBOutlet UIView *containerView;
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
    self.containerView.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitHeader;
    self.tintColor = [UIColor wmf_blueTintColor];
    self.rightButtonWidthConstraintConstant = self.rightButtonWidthConstraint.constant;
    self.rightButton.hidden = YES;
    self.rightButton.tintColor = [UIColor wmf_blueTintColor];
    self.rightButton.isAccessibilityElement = YES;
    self.rightButton.accessibilityTraits = UIAccessibilityTraitButton;
    @weakify(self);
    [self bk_whenTapped:^{
        @strongify(self);
        if (self.whenTapped) {
            self.whenTapped();
        }
    }];
    [self wmf_configureSubviewsForDynamicType];
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

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self updateAccessibilityLabel];
}

- (void)setSubTitle:(NSString *)subTitle {
    self.subTitleLabel.text = subTitle;
    [self updateAccessibilityLabel];
}

- (void)setTitleColor:(UIColor *)titleColor {
    self.titleLabel.textColor = titleColor;
}

- (void)setSubTitleColor:(UIColor *)subTitleColor {
    self.subTitleLabel.textColor = subTitleColor;
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
    self.containerView.accessibilityLabel = [components componentsJoinedByString:@" "];
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
