//
//  WMFImageGalleryDetailOverlayView.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryDetailOverlayView.h"
#import "PaddedLabel.h"
#import "UIFont+WMFStyle.h"
#import "WikiGlyph_Chars.h"
#import "UILabel+WMFStyling.h"
#import "MWKLicense+ToGlyph.h"
#import "NSParagraphStyle+WMFNaturalAlignmentStyle.h"

static double const WMFImageGalleryLicenseFontSize       = 19.0;
static double const WMFImageGalleryLicenseBaselineOffset = -1.5;
static double const WMFImageGalleryOwnerFontSize         = 11.f;

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, weak) IBOutlet UILabel* imageDescriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton* ownerButton;

- (IBAction)didTapOwnerButton;

@end


static NSAttributedString* ConcatOwnerAndLicense(NSString* owner, MWKLicense* license){
    if (!owner && !license) {
        return nil;
    }
    NSMutableAttributedString* result = [NSMutableAttributedString new];
    NSString* licenseGlyph            = [license toGlyph] ? : WIKIGLYPH_CITE;
    if (licenseGlyph) {
        // hand-tuning glyph size & baseline offset until all glyphs are positioned & padded in a uniform way
        [result appendAttributedString:
         [[NSAttributedString alloc]
          initWithString:licenseGlyph
              attributes:@{NSFontAttributeName: [UIFont wmf_glyphFontOfSize:WMFImageGalleryLicenseFontSize],
                           NSForegroundColorAttributeName: [UIColor whiteColor],
                           NSBaselineOffsetAttributeName: @(WMFImageGalleryLicenseBaselineOffset)}]];
    }


    NSAttributedString* attributedOwnerAndSeparator =
        [[NSAttributedString alloc]
         initWithString:[@" " stringByAppendingString:owner]
             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:WMFImageGalleryOwnerFontSize],
                          NSForegroundColorAttributeName: [UIColor whiteColor]}];

    [result appendAttributedString:attributedOwnerAndSeparator];

    [result addAttribute:NSParagraphStyleAttributeName
                   value:[NSParagraphStyle wmf_naturalAlignmentStyle]
                   range:NSMakeRange(0, result.length)];

    return result;
}

@implementation WMFImageGalleryDetailOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    [NSException raise:@"ViewRequiresNibInstantiationException"
                format:@"%@ is expecting to be loaded from a nib.", NSStringFromClass([self class])];
    return nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.ownerButton.titleLabel wmf_applyDropShadow];
    [self.imageDescriptionLabel wmf_applyDropShadow];
}

- (IBAction)didTapOwnerButton {
    if (self.ownerTapCallback) {
        self.ownerTapCallback();
    }
}

- (void)setGroupAlpha:(float)alpha {
    self.alpha                       = alpha;
    self.imageDescriptionLabel.alpha = alpha;
    self.ownerButton.alpha           = alpha;
}

- (NSString*)imageDescription {
    return self.imageDescriptionLabel.attributedText.string;
}

- (void)setImageDescription:(NSString*)imageDescription {
    if (!imageDescription) {
        self.imageDescriptionLabel.attributedText = nil;
    } else {
        self.imageDescriptionLabel.attributedText =
            [[NSAttributedString alloc] initWithString:imageDescription
                                            attributes:@{
                 NSParagraphStyleAttributeName: [NSParagraphStyle wmf_naturalAlignmentStyle]
             }];
    }
}

- (void)setLicense:(MWKLicense*)license owner:(NSString*)owner {
    [self.ownerButton setAttributedTitle:ConcatOwnerAndLicense(owner, license) forState:UIControlStateNormal];
}

@end
