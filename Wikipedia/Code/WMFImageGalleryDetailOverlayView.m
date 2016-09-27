#import "WMFImageGalleryDetailOverlayView.h"
#import "UIFont+WMFStyle.h"
#import "WikiGlyph_Chars.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "WMFGradientView.h"
#import <Masonry/Masonry.h>

static double const WMFImageGalleryOwnerFontSize = 11.f;

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

    //    [self.detailOverlayView mas_makeConstraints:^(MASConstraintMaker* make) {
    //        make.height.lessThanOrEqualTo(@(WMFImageGalleryMaxDetailHeight)).with.priorityHigh();
    //        make.leading.trailing.and.bottom.equalTo(self.contentView);
    //    }];

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
    return self.imageDescriptionLabel.attributedText.string;
}

- (void)setImageDescription:(NSString *)imageDescription {
    if (!imageDescription) {
        self.imageDescriptionLabel.attributedText = nil;
    } else {
        self.imageDescriptionLabel.attributedText =
            [[NSAttributedString alloc] initWithString:imageDescription
                                            attributes:@{
                                                NSParagraphStyleAttributeName: [NSParagraphStyle wmf_naturalAlignmentStyle],
                                            }];
    }
}

- (nullable UIImageView *)newImageViewForLicenseWithCode:(nonnull NSString *)code {
    NSString *imageName = [@[@"license", code] componentsJoinedByString:@"-"];

    UIImage *image = [UIImage imageNamed:imageName];
    CGFloat dimension = image.size.width;

    if (!image) {
        return nil;
    }

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(1.2 * dimension));
        make.top.and.bottom.equalTo(self.ownerStackView);
    }];
    return imageView;
}

- (void)setLicense:(MWKLicense *)license owner:(NSString *)owner {
    NSArray *subviews = [self.ownerStackView.arrangedSubviews copy];
    for (UIView *view in subviews) {
        [self.ownerStackView removeArrangedSubview:view];
    }

    BOOL didAddLicenseIcon = NO;
    NSString *code = [license.code lowercaseString];
    if (code) {
        NSArray<NSString *> *components = [code componentsSeparatedByString:@"-"];
        for (NSString *code in components) {
            UIImageView *imageView = [self newImageViewForLicenseWithCode:code];
            if (!imageView) {
                continue;
            }
            didAddLicenseIcon = YES;
            [self.ownerStackView addArrangedSubview:imageView];
        }
    } else {
        UIImageView *imageView = [self newImageViewForLicenseWithCode:@"generic"];
        if (imageView && license.shortDescription) {
            didAddLicenseIcon = YES;
            [self.ownerStackView addArrangedSubview:imageView];
            UILabel *licenseDescriptionLabel = [[UILabel alloc] init];
            licenseDescriptionLabel.font = [UIFont systemFontOfSize:WMFImageGalleryOwnerFontSize];
            licenseDescriptionLabel.textColor = [UIColor whiteColor];
            licenseDescriptionLabel.text = [NSString stringWithFormat:@" %@", license.shortDescription];
            if (licenseDescriptionLabel) {
                [self.ownerStackView addArrangedSubview:licenseDescriptionLabel];
            }
        }
    }

    if (!owner) {
        return;
    }

    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:WMFImageGalleryOwnerFontSize];
    label.textColor = [UIColor whiteColor];
    label.text = didAddLicenseIcon ? [NSString stringWithFormat:@" %@", owner] : owner;
    [self.ownerStackView addArrangedSubview:label];
}

@end
