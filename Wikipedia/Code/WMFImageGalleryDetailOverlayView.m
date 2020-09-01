#import "WMFImageGalleryDetailOverlayView.h"
#import "Wikipedia-Swift.h"
@import WMF.MWKLicense;

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, strong) IBOutlet WMFImageGalleryDescriptionTextView *imageDescriptionTextView; // Text view allows scrolling excess text.
@property (nonatomic, strong) IBOutlet UIButton *ownerButton;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) IBOutlet WMFLicenseView *ownerStackView;
@property (nonatomic, strong) IBOutlet UIImageView *lineImageView;

- (IBAction)didTapOwnerButton;
- (IBAction)didTapInfoButton;

@end

@implementation WMFImageGalleryDetailOverlayView

- (void)setMaximumDescriptionHeight:(CGFloat)maximumDescriptionHeight {
    _maximumDescriptionHeight = maximumDescriptionHeight;
    self.imageDescriptionTextView.availableHeight = maximumDescriptionHeight;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.infoButton.imageView.contentMode = UIViewContentModeCenter;
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

- (IBAction)didTapDescriptionTextView {
    if (self.descriptionTapCallback) {
        self.descriptionTapCallback();
    }
}

- (IBAction)didTapBottomGradientView {
    if (self.descriptionTapCallback) {
        self.descriptionTapCallback();
    }
}

- (void)toggleDescriptionOpenState {
    [self.imageDescriptionTextView toggleOpenState];
    self.lineImageView.image = (self.imageDescriptionTextView.openStatePercent == GalleryDescriptionOpenStatePercentNormal) ? [UIImage imageNamed:@"gallery-line"] : [UIImage imageNamed:@"gallery-line-bent"];
}

- (NSString *)imageDescription {
    return self.imageDescriptionTextView.text;
}

- (void)setImageDescription:(NSString *)imageDescription {
    self.imageDescriptionTextView.text = imageDescription;
    self.lineImageView.alpha = imageDescription.length > 0 ? 1.0 : 0.0;
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
