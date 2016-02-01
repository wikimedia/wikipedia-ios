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

static CGFloat WMFTextualSaveButtonImageToTextPadding = 12.f;

@interface WMFTextualSaveButton ()

/**
 *  Flag which represents whether or not the receiver was being previewed in Interface Builder (IB).
 */
@property (nonatomic, assign, getter = isInterfaceBuilderPreviewing) BOOL interfaceBuilderPreviewing;

/**
 *  The image view shown to the left (in LTR) of the text.
 */
@property (nonatomic, strong) UIImageView* saveIconImageView;

/**
 *  The text shown to the right of the image which describes the future state of the article.
 *
 *  In other words, if the article isn't saved, it says "Save for later".
 */
@property (nonatomic, strong) UILabel* saveTextLabel;

@end

@implementation WMFTextualSaveButton

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setupSubviews];
    [self applyInitialState];
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    self.interfaceBuilderPreviewing = YES;
    if (!self.saveIconImageView.image || !self.saveTextLabel.text) {
        // re-apply initial state, using assets from the correct bundle
        [self applyInitialState];
        NSParameterAssert(self.saveTextLabel.text);
        NSParameterAssert(self.saveIconImageView.image);
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    [self setNeedsUpdateConstraints];
}

#pragma mark - Accessors

- (UIImage*)iconImage {
    NSString* imageName = self.selected ? @"save-filled-mini" : @"save-mini";
    if (self.isInterfaceBuilderPreviewing) {
        // HAX: NSBundle.mainBundle is _not_ the application when the view is being created by IB
        return [UIImage imageNamed:imageName
                                     inBundle:[NSBundle bundleForClass:[self class]]
                compatibleWithTraitCollection:self.traitCollection];
    } else {
        return [UIImage imageNamed:imageName];
    }
}

- (NSString*)labelText {
    NSString* key = self.selected ? @"button-saved-for-later" : @"button-save-for-later";
    if (self.isInterfaceBuilderPreviewing) {
        // HAX: NSBundle.mainBundle is _not_ the application when the view is being created by IB
        return [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil];
    } else {
        return MWLocalizedString(key, nil);
    }
}

- (CGSize)intrinsicContentSize {
    // NOTE(bgerstle): need custom intrinsic content size to prevent compression beyond intrinsic size of subviews
    CGSize imageViewIntrinsicContentSize = self.saveIconImageView.intrinsicContentSize;
    CGSize labelIntrinsicContentSize     = self.saveTextLabel.intrinsicContentSize;
    CGSize intrinsicSize                 = (CGSize){
        .width = imageViewIntrinsicContentSize.width
                 + labelIntrinsicContentSize.width
                 + WMFTextualSaveButtonImageToTextPadding,
        .height = fmaxf(imageViewIntrinsicContentSize.height, labelIntrinsicContentSize.height)
    };
    return intrinsicSize;
}

#pragma mark - View Setup

- (void)setupSubviews {
    self.saveIconImageView                    = [UIImageView new];
    self.saveIconImageView.contentMode        = UIViewContentModeCenter;
    self.saveIconImageView.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    [self addSubview:self.saveIconImageView];

    self.saveTextLabel                      = [UILabel new];
    self.saveTextLabel.numberOfLines        = 1;
    self.saveTextLabel.textAlignment        = NSTextAlignmentNatural;
    self.saveTextLabel.font                 = [UIFont boldSystemFontOfSize:14.f];
    self.saveTextLabel.highlightedTextColor = [UIColor lightGrayColor];
    self.saveTextLabel.tintAdjustmentMode   = UIViewTintAdjustmentModeAutomatic;
    [self.saveTextLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:self.saveTextLabel];;

    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    [super updateConstraints];

    // imageView must hug content, otherwise it will expand and "push" label towards opposite edge
    [self.saveIconImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.saveIconImageView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.equalTo(self);
        if (self.contentMode == UIViewContentModeBottom) {
            make.bottom.equalTo(self);
        } else {
            if (self.contentMode != UIViewContentModeScaleToFill) {
                DDLogWarn(@"No custom layout for %ld, using default scale to fill behavior.", self.contentMode);
            }
            make.top.and.bottom.equalTo(self);
        }
    }];

    [self.saveTextLabel mas_makeConstraints:^(MASConstraintMaker* make) {
        make.trailing.equalTo(self);
        // make sure icon & button aren't squished together
        make.leading.equalTo(self.saveIconImageView.mas_trailing).with.offset(WMFTextualSaveButtonImageToTextPadding);
        if (self.contentMode == UIViewContentModeBottom) {
            make.bottom.equalTo(self);
        } else {
            if (self.contentMode != UIViewContentModeScaleToFill) {
                DDLogWarn(@"No custom layout for %ld, using default scale to fill behavior.", self.contentMode);
            }
            make.trailing.top.and.bottom.equalTo(self);
        }
    }];
}

- (void)applyInitialState {
    [self applySelectedState:NO];
    [self applyTintColor];
}

- (void)applySelectedState:(BOOL)animated {
    dispatch_block_t animations = ^{
        self.saveIconImageView.image = [self iconImage];
        self.saveTextLabel.text      = [self labelText];
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
    self.saveTextLabel.textColor     = self.highlighted ? [self.tintColor wmf_colorByApplyingDim] : self.tintColor;
    self.saveIconImageView.tintColor = self.tintColor;
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
