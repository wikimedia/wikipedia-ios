//
//  WMFTextualSaveButton.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFTextualSaveButton.h"
#import <Masonry/Masonry.h>
#import "UIColor+WMFStyle.h"

@implementation WMFTextualSaveButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupViews];
        [self applySelectedState];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [self applySelectedState];
    }
    return self;
}

#pragma mark - Accessors

- (UIImage*)iconImage {
    return self.selected ? [UIImage imageNamed:@"save-filled-mini"] : [UIImage imageNamed:@"save-mini"];
}

- (NSString*)labelText {
    return self.selected ? MWLocalizedString(@"button-saved-for-later", nil) : MWLocalizedString(@"button-save-for-later", nil);
}

#pragma mark - View Setup

- (void)setupViews {
    [self addMissingViews];

    // subviews always follow super's tint color
    self.saveIconImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    self.saveTextLabel.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
}

/**
 *  Add any views which weren't set to the receiver's IBOutlet's in interface builder.
 *
 *  This allows the component to be created programmatically, dropped into IB using default views, and customizing one
 *  or more subviews.
 */
- (void)addMissingViews {
    if (!self.saveIconImageView) {
        UIImageView* saveIconImageView = [UIImageView new];
        saveIconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:saveIconImageView];
        self.saveIconImageView = saveIconImageView;

        [self.saveIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.and.bottom.equalTo(self);
        }];
    }

    if (!self.saveTextLabel) {
        UILabel* saveTextLabel = [UILabel new];
        saveTextLabel.numberOfLines = 1;
        saveTextLabel.textAlignment = NSTextAlignmentNatural;
        saveTextLabel.font = [UIFont systemFontOfSize:18.f];
        saveTextLabel.highlightedTextColor = [UIColor lightGrayColor];
        [self addSubview:saveTextLabel];
        self.saveTextLabel = saveTextLabel;

        [self.saveTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.top.and.bottom.equalTo(self);
            // make sure icon & button aren't squished together
            make.leading.equalTo(self.saveIconImageView.mas_trailing).with.offset(12.f);
        }];
    }
}

- (void)applySelectedState {
    [UIView transitionWithView:self
                      duration:[CATransaction animationDuration]
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.saveIconImageView.image = [self iconImage];
        self.saveTextLabel.text = [self labelText];
    }
                    completion:nil];
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    // dim subviews
    self.tintAdjustmentMode = highlighted ? UIViewTintAdjustmentModeDimmed : UIViewTintAdjustmentModeNormal;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    self.saveTextLabel.textColor = self.highlighted ? [self.tintColor wmf_colorByApplyingDim] : self.tintColor;
    self.saveIconImageView.tintColor = self.tintColor;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self applySelectedState];
}

@end
