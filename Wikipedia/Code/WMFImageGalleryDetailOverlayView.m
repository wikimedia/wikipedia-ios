#import "WMFImageGalleryDetailOverlayView.h"
#import "Wikipedia-Swift.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
#import "WMFGradientView.h"
@import WMF.MWKLicense;

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, strong) IBOutlet WMFScreenHeightConstrainedGradientTextView *imageDescriptionTextView; // Text view allows scrolling excess text.
@property (nonatomic, strong) IBOutlet UIButton *ownerButton;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) IBOutlet WMFLicenseView *ownerStackView;
@property (nonatomic, strong) IBOutlet WMFGradientView *gradientView;

- (IBAction)didTapOwnerButton;
- (IBAction)didTapInfoButton;

@end

@implementation WMFImageGalleryDetailOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.infoButton.imageView.contentMode = UIViewContentModeCenter;
    [self.ownerButton.titleLabel wmf_applyDropShadow];

    [self.gradientView.gradientLayer setLocations:@[@0.0, @0.5, @1.0]];
    [self.gradientView.gradientLayer setColors:@[
        (id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor,
        (id)[UIColor clearColor].CGColor
    ]];
    // default start/end points, to be adjusted w/ image size
    [self.gradientView.gradientLayer setStartPoint:CGPointMake(0.5, 1.0)];
    [self.gradientView.gradientLayer setEndPoint:CGPointMake(0.5, 0.0)];
    [self wmf_configureSubviewsForDynamicType];
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

- (IBAction)didTapImageDescription {
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self.imageDescriptionTextView toggleOpenState];
                         [self.superview layoutIfNeeded];
                     }
                     completion:NULL];
}

- (NSString *)imageDescription {
    return self.imageDescriptionTextView.text;
}

- (void)setImageDescription:(NSString *)imageDescription {
    self.imageDescriptionTextView.text = imageDescription;
}

- (void)setImageDescriptionIsRTL:(BOOL)isRTL {
    self.imageDescriptionTextView.textAlignment = isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
}

- (void)setLicense:(MWKLicense *)license owner:(NSString *)owner {
    NSString *code = [license.code lowercaseString];
    if (code) {
        NSArray<NSString *> *codes = [code componentsSeparatedByString:@"-"];
        self.ownerStackView.licenseCodes = codes;
    } else {
        self.ownerStackView.licenseCodes = @[@"generic"];
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

- (UILabel *)newLicenseLabel {
    UILabel *label = [[UILabel alloc] init];
    [label wmf_configureSubviewsForDynamicType];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    label.textColor = [UIColor whiteColor];
    return label;
}

@end
