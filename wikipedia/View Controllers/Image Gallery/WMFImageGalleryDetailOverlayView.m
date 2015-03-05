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

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, weak) IBOutlet UILabel* imageDescriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton* ownerButton;

- (IBAction)didTapOwnerButton;

@end

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
    self.alpha = alpha;
    self.imageDescriptionLabel.alpha = alpha;
    self.ownerButton.alpha = alpha;
}

- (void)setGroupHidden:(BOOL)hidden {
    self.hidden = hidden;
    self.imageDescriptionLabel.hidden = hidden;
    self.ownerButton.hidden = hidden;
}

@end
