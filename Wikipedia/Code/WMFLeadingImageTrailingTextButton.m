#import "WMFLeadingImageTrailingTextButton.h"
#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"

/**
 *  RTL-compliant control which lays out a button with an icon on the left and text on the right.
 *
 *  @discussion
 *  Also, AutoLayout constraints are used to ensure RTL compliance across iOS 8 & 9. Initial implementaion of a textual
 *   button used @c UIButton "out of the box" with @c titleEdgeInsets to space the icon & text.  The problems with
 *  this approach were:
 *
 *    - iOS 8: Icon & text were still LTR when device was set to RTL language.<br/>
 *    - iOS 9: Icon & text were overlapping each other since the inset wasn't also flipped.
 *
 *  The iOS 9 issue could've been worked around easily enough by flipping the inset (and setting the
 *  @c contentHorizontalAlignment), but a custom control was needed for complete RTL compliance in iOS 8 & 9. See
 *  https://phabricator.wikimedia.org/T121681 for more information, including screenshots.
 */

//IB_DESIGNABLE

@interface WMFLeadingImageTrailingTextButton ()

@property (nonatomic, assign, readwrite, getter=isInterfaceBuilderPreviewing) BOOL interfaceBuilderPreviewing;

@property (nonatomic, strong, readwrite) UIImageView *iconImageView;

@property (nonatomic, strong, readwrite) UILabel *textLabel;

@end

@implementation WMFLeadingImageTrailingTextButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _spaceBetweenIconAndText = 12.0;
        [self setupSubviews];
        [self applyInitialState];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _spaceBetweenIconAndText = 12.0;
        [self setupSubviews];
        [self applyInitialState];
    }
    return self;
}

- (void)sizeToFit {
    [super sizeToFit];
    CGRect f = self.frame;
    f.size = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    self.frame = f;
}

//- (void)prepareForInterfaceBuilder {
//    [super prepareForInterfaceBuilder];
//    self.interfaceBuilderPreviewing = YES;
//    if (!self.iconImageView.image || !self.textLabel.text) {
//        // re-apply initial state, using assets from the correct bundle
//        self.textLabel.text = @"";
//        [self applyInitialState];
//    }
//}

- (void)setspaceBetweenIconAndText:(CGFloat)spaceBetweenIconAndText {
    _spaceBetweenIconAndText = spaceBetweenIconAndText;
    [self applyConstraints];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
    _edgeInsets = edgeInsets;
    [self applyConstraints];
}

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    [self applySelectedState:NO];
}

- (void)setSelectedIconImage:(UIImage *)selectedIconImage {
    _selectedIconImage = selectedIconImage;
    [self applySelectedState:NO];
}

- (void)setLabelText:(NSString *)labelText {
    _labelText = labelText;
    [self applySelectedState:NO];
}

- (void)setSelectedLabelText:(NSString *)selectedLabelText {
    _selectedLabelText = selectedLabelText;
    [self applySelectedState:NO];
}

#pragma mark - View Setup

- (void)setupSubviews {
    self.iconImageView = [UIImageView new];
    self.iconImageView.contentMode = UIViewContentModeCenter;
    self.iconImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    self.iconImageView.isAccessibilityElement = NO;
    [self addSubview:self.iconImageView];

    // imageView must hug content, otherwise it will expand and "push" label towards opposite edge
    [self.iconImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.textLabel = [UILabel new];
    self.textLabel.numberOfLines = 1;
    self.textLabel.textAlignment = NSTextAlignmentNatural;
    self.textLabel.highlightedTextColor = [UIColor lightGrayColor];
    self.textLabel.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    self.textLabel.isAccessibilityElement = NO;
    [self.textLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:self.textLabel];
    [self applyConstraints];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    self.textLabel.font = [UIFont wmf_preferredFontForFontFamily:WMFFontFamilySystemBold
                                                   withTextStyle:UIFontTextStyleSubheadline
                                   compatibleWithTraitCollection:self.traitCollection];
}

- (void)applyConstraints {
    UIEdgeInsets modified = self.edgeInsets;

    //right and bottom need negative numbers
    modified.bottom = -modified.bottom;
    modified.right = -modified.right;

    //flip left and right for RTL
    if ([[UIApplication sharedApplication] wmf_isRTL]) {
        modified.left = -modified.right;
        modified.right = -self.edgeInsets.left;
    }

    [self.iconImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.mas_leading).with.offset(modified.left);
        make.top.equalTo(self.mas_top).with.offset(modified.top);
        make.bottom.equalTo(self.mas_bottom).with.offset(modified.bottom);
    }];
    [self.textLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.mas_trailing).with.offset(modified.right);
        make.top.equalTo(self.mas_top).with.offset(modified.top);
        make.bottom.equalTo(self.mas_bottom).with.offset(modified.bottom);
        // make sure icon & button aren't squished together
        make.leading.equalTo(self.iconImageView.mas_trailing).with.offset(self.spaceBetweenIconAndText);
    }];
}

- (void)applyInitialState {
    [self applySelectedState:NO];
    [self applyTintColor];
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)applySelectedState:(BOOL)animated {
    dispatch_block_t animations = ^{
        self.iconImageView.image = self.selected && self.selectedIconImage ? self.selectedIconImage : self.iconImage;
        self.textLabel.text = self.selected && self.selectedLabelText ? self.selectedLabelText : self.labelText;
        self.accessibilityLabel = self.selected ? self.selectedActionText ?: self.textLabel.text : self.deselectedActionText ?: self.textLabel.text;
    };
    if (!animated) {
        animations();
        return;
    }
    [UIView transitionWithView:self
                      duration:[CATransaction animationDuration]
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:animations
                    completion:nil];
}

- (void)applyTintColor {
    self.textLabel.textColor = self.highlighted ? [self.tintColor wmf_colorByApplyingDim] : self.tintColor;
    self.iconImageView.tintColor = self.tintColor;
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    // dim subviews
    self.tintAdjustmentMode = highlighted ? UIViewTintAdjustmentModeDimmed : UIViewTintAdjustmentModeNormal;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self applyTintColor];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self applySelectedState:YES && !self.interfaceBuilderPreviewing];
}

@end

@implementation WMFLeadingImageTrailingTextButton (WMFConfiguration)

- (void)configureAsSaveButton {
    self.iconImage = [UIImage imageNamed:@"save-mini"
                                inBundle:[NSBundle bundleForClass:[self class]]
           compatibleWithTraitCollection:self.traitCollection];
    self.selectedIconImage = [UIImage imageNamed:@"save-filled-mini"
                                        inBundle:[NSBundle bundleForClass:[self class]]
                   compatibleWithTraitCollection:self.traitCollection];

    self.labelText = NSLocalizedStringWithDefaultValue(@"button-save-for-later", nil, self.bundleForLocalization, @"Save for later", "Longer button text for save button used in various places.");
    self.selectedLabelText = NSLocalizedStringWithDefaultValue(@"button-saved-for-later", nil, self.bundleForLocalization, @"Saved for later", "Longer button text for already saved button used in various places.");

    self.selectedActionText = NSLocalizedStringWithDefaultValue(@"unsave-action", nil, self.bundleForLocalization, @"Unsave", "Accessibility action description for 'Unsave'");
    self.deselectedActionText = NSLocalizedStringWithDefaultValue(@"save-action", nil, self.bundleForLocalization, @"Save", "Accessibility action description for 'Save'\n{{Identical|Save}}");
}

- (void)configureAsReportBugButton {
    self.spaceBetweenIconAndText = 5.0;
    self.iconImage = [UIImage imageNamed:@"settings-feedback"
                                inBundle:[NSBundle bundleForClass:[self class]]
           compatibleWithTraitCollection:self.traitCollection];
    self.labelText = NSLocalizedStringWithDefaultValue(@"button-report-a-bug", nil, self.bundleForLocalization, @"Report a bug", "Button text for reporting a bug");
    self.selectedActionText = NSLocalizedStringWithDefaultValue(@"button-report-a-bug", nil, self.bundleForLocalization, @"Report a bug", "Button text for reporting a bug");
    self.deselectedActionText = NSLocalizedStringWithDefaultValue(@"button-report-a-bug", nil, self.bundleForLocalization, @"Report a bug", "Button text for reporting a bug");
}

- (NSBundle *)bundleForLocalization {
    if (self.isInterfaceBuilderPreviewing) {
        // HAX: NSBundle.mainBundle is _not_ the application when the view is being created by IB
        return [NSBundle bundleForClass:[self class]];
    } else {
        return NSBundle.mainBundle;
    }
}

- (void)configureAsNotifyTrendingButton {
    self.layer.borderColor = [UIColor wmf_blueTint].CGColor;
    self.layer.borderWidth = 1.0;
    self.layer.cornerRadius = 5.0;
    self.spaceBetweenIconAndText = 5.0;
    self.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    self.iconImage = [UIImage imageNamed:@"notificationsIconV1"
                                inBundle:[NSBundle bundleForClass:[self class]]
           compatibleWithTraitCollection:self.traitCollection];
    self.labelText = NSLocalizedStringWithDefaultValue(@"feed-news-notification-button-text", nil, self.bundleForLocalization, @"Turn on notifications", "Text for button to turn on trending news notifications");

    self.textLabel.textColor = [UIColor wmf_blueTint];
    self.textLabel.adjustsFontSizeToFitWidth = YES;

    self.selectedActionText = NSLocalizedStringWithDefaultValue(@"feed-news-notification-button-text", nil, self.bundleForLocalization, @"Turn on notifications", "Text for button to turn on trending news notifications");
    self.deselectedActionText = NSLocalizedStringWithDefaultValue(@"feed-news-notification-button-text", nil, self.bundleForLocalization, @"Turn on notifications", "Text for button to turn on trending news notifications");
}

@end
