#import "WMFImageGalleryDetailOverlayView.h"
#import "UIFont+WMFStyle.h"
#import "Wikipedia-Swift.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "WMFGradientView.h"
#import <Masonry/Masonry.h>

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, strong) IBOutlet UILabel *imageDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton *ownerButton;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) IBOutlet UIStackView *ownerStackView;
@property (nonatomic, strong) IBOutlet UIStackView *ownerLabel;

@property (nonatomic, strong) WMFGradientView *gradientView;

- (IBAction)didTapOwnerButton;
- (IBAction)didTapInfoButton;

@end

@implementation WMFImageGalleryDetailOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.infoButton.imageView.contentMode = UIViewContentModeCenter;
    [self.ownerButton.titleLabel wmf_applyDropShadow];
    [self.imageDescriptionLabel wmf_applyDropShadow];

    WMFGradientView *gradientView = [WMFGradientView new];
    [gradientView.gradientLayer setLocations:@[@0, @1]];
    [gradientView.gradientLayer setColors:@[(id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
                                            (id)[UIColor clearColor].CGColor]];
    // default start/end points, to be adjusted w/ image size
    [gradientView.gradientLayer setStartPoint:CGPointMake(0.5, 1.0)];
    [gradientView.gradientLayer setEndPoint:CGPointMake(0.5, 0.0)];
    gradientView.userInteractionEnabled = NO;
    [self addSubview:gradientView];
    [self sendSubviewToBack:gradientView];
    self.gradientView = gradientView;

    [self.gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self wmf_configureSubviewsForDynamicType];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.frame.size.height > 0.0) {
        // start gradient at the top of the image description label
        double const imageDescriptionTop =
            self.frame.size.height - CGRectGetMinY(self.imageDescriptionLabel.frame);
        double const relativeImageDescriptionTop = 1.0 - imageDescriptionTop / self.frame.size.height;
        self.gradientView.gradientLayer.startPoint = CGPointMake(0.5, relativeImageDescriptionTop);
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        NSLayoutConstraint *maxHeightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.superview attribute:NSLayoutAttributeHeight multiplier:0.3f constant:0.0f];
        [self.superview addConstraint:maxHeightConstraint];
    }
}

- (IBAction)didTapOwnerButton {
    if (self.ownerTapCallback) {
        self.ownerTapCallback();
    }
}

- (IBAction)didTapInfoButton {
    if (self.infoTapCallback) {
        self.infoTapCallback();
    }
}

- (NSString *)imageDescription {
    return self.imageDescriptionLabel.text;
}

- (void)setImageDescription:(NSString *)imageDescription {
    self.imageDescriptionLabel.text = imageDescription;
}

- (BOOL)addImageViewForLicenseWithCode:(nonnull NSString *)code toStackView:(UIStackView *)stackView {
    NSString *imageName = [@[@"license", code] componentsJoinedByString:@"-"];

    UIImage *image = [UIImage imageNamed:imageName];

    if (!image) {
        return NO;
    }

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [stackView addArrangedSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.equalTo(self.ownerStackView);
    }];

    UILabel *space = [[UILabel alloc] init];
    space.text = @" ";
    [space setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [stackView addArrangedSubview:space];

    return YES;
}

- (void)setLicense:(MWKLicense *)license owner:(NSString *)owner {
    NSArray *subviews = [self.ownerStackView.arrangedSubviews copy];
    for (UIView *view in subviews) {
        [self.ownerStackView removeArrangedSubview:view];
    }

    NSString *code = [license.code lowercaseString];
    if (code) {
        NSArray<NSString *> *components = [code componentsSeparatedByString:@"-"];
        for (NSString *code in components) {
            [self addImageViewForLicenseWithCode:code toStackView:self.ownerStackView];
        }
    } else {
        [self addImageViewForLicenseWithCode:@"generic" toStackView:self.ownerStackView];
        if (license.shortDescription) {
            UILabel *licenseDescriptionLabel = [self newLicenseLabel];
            NSString *format = owner ? @"%@ \u2022 " : @"%@";
            licenseDescriptionLabel.text = [NSString stringWithFormat:format, license.shortDescription];
            [self.ownerStackView addArrangedSubview:licenseDescriptionLabel];
        }
    }

    if (!owner) {
        return;
    }

    UILabel *ownerLabel = [self newLicenseLabel];
    ownerLabel.text = owner;
    [self.ownerStackView addArrangedSubview:ownerLabel];
}

- (UILabel*)newLicenseLabel {
    UILabel *label = [[UILabel alloc] init];
    [label wmf_configureSubviewsForDynamicType];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    label.textColor = [UIColor whiteColor];
    return label;
}

@end
