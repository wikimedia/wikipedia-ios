#import "WMFImageGalleryDetailOverlayView.h"
#import "UIFont+WMFStyle.h"
#import "WikiGlyph_Chars.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "WMFGradientView.h"
#import <Masonry/Masonry.h>

static double const WMFImageGalleryLicenseFontSize = 19.0;
static double const WMFImageGalleryLicenseBaselineOffset = -1.5;
static double const WMFImageGalleryOwnerFontSize = 11.f;

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, strong) IBOutlet UILabel *imageDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIButton *ownerButton;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;

@property (nonatomic, strong) WMFGradientView *gradientView;

- (IBAction)didTapOwnerButton;
- (IBAction)didTapInfoButton;

@end

static NSAttributedString *ConcatOwnerAndLicense(NSString *owner, MWKLicense *license) {
    if (!owner && !license) {
        return nil;
    }
    NSMutableAttributedString *result = [NSMutableAttributedString new];
    NSString *licenseGlyph = [license toGlyph] ?: WIKIGLYPH_CITE;
    if (licenseGlyph) {
        // hand-tuning glyph size & baseline offset until all glyphs are positioned & padded in a uniform way
        [result appendAttributedString:
                    [[NSAttributedString alloc]
                        initWithString:licenseGlyph
                            attributes:@{ NSFontAttributeName : [UIFont wmf_glyphFontOfSize:WMFImageGalleryLicenseFontSize],
                                          NSForegroundColorAttributeName : [UIColor whiteColor],
                                          NSBaselineOffsetAttributeName : @(WMFImageGalleryLicenseBaselineOffset) }]];
    }

    NSAttributedString *attributedOwnerAndSeparator =
        [[NSAttributedString alloc]
            initWithString:[@" " stringByAppendingString:owner]
                attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:WMFImageGalleryOwnerFontSize],
                             NSForegroundColorAttributeName : [UIColor whiteColor]}];

    [result appendAttributedString:attributedOwnerAndSeparator];

    [result addAttribute:NSParagraphStyleAttributeName
                   value:[NSParagraphStyle wmf_tailTruncatingNaturalAlignmentStyle]
                   range:NSMakeRange(0, result.length)];

    return result;
}

@implementation WMFImageGalleryDetailOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.ownerButton.titleLabel wmf_applyDropShadow];
    [self.imageDescriptionLabel wmf_applyDropShadow];

    //    [self.detailOverlayView mas_makeConstraints:^(MASConstraintMaker* make) {
    //        make.height.lessThanOrEqualTo(@(WMFImageGalleryMaxDetailHeight)).with.priorityHigh();
    //        make.leading.trailing.and.bottom.equalTo(self.contentView);
    //    }];

    WMFGradientView *gradientView = [WMFGradientView new];
    [gradientView.gradientLayer setLocations:@[ @0, @1 ]];
    [gradientView.gradientLayer setColors:@[ (id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
                                             (id)[UIColor clearColor].CGColor ]];
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
                                                NSParagraphStyleAttributeName : [NSParagraphStyle wmf_naturalAlignmentStyle],
                                            }];
    }
}

- (void)setLicense:(MWKLicense *)license owner:(NSString *)owner {
    [self.ownerButton setAttributedTitle:ConcatOwnerAndLicense(owner, license) forState:UIControlStateNormal];
}

@end
