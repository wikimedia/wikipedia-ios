#import "WMFImageGalleryDetailOverlayView.h"
#import "Wikipedia-Swift.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
@import WMF.MWKLicense;

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, strong) IBOutlet WMFScreenHeightConstrainedTextView *imageDescriptionTextView; // Text view allows scrolling excess text.
@property (nonatomic, strong) IBOutlet UIButton *ownerButton;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) IBOutlet WMFLicenseView *ownerStackView;

- (IBAction)didTapOwnerButton;
- (IBAction)didTapInfoButton;

@end

@implementation WMFImageGalleryDetailOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.infoButton.imageView.contentMode = UIViewContentModeCenter;
    [self.ownerButton.titleLabel wmf_applyDropShadow];
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

- (void)toggleDescriptionOpenState {
    [self.imageDescriptionTextView toggleOpenState];
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
