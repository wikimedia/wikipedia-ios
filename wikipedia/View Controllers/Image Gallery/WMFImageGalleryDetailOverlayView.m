//
//  WMFImageGalleryDetailOverlayView.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryDetailOverlayView.h"
#import <QuartzCore/CAGradientLayer.h>
#import "PaddedLabel.h"
#import "UIFont+WMFStyle.h"
#import "WikiGlyph_Chars.h"
#import "UILabel+WMFStyling.h"

@interface WMFImageGalleryDetailOverlayView ()
@property (nonatomic, weak) IBOutlet UILabel *imageDescriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton *ownerButton;

- (IBAction)didTapOwnerButton;

@end

@implementation WMFImageGalleryDetailOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    [NSException raise:@"ViewRequiresNibInstantiationException"
                format:@"%@ is expecting to be loaded from a nib.", NSStringFromClass([self class])];
    return nil;
}

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (CAGradientLayer*)gradientLayer
{
    return (CAGradientLayer*)self.layer;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[self gradientLayer] setLocations:@[@0, @0.6, @1]];
    [[self gradientLayer] setColors:@[(id)[UIColor blackColor].CGColor,
                                      (id)[UIColor colorWithWhite:0 alpha:0.55859375].CGColor,
                                      (id)[UIColor clearColor].CGColor]];
    [[self gradientLayer] setStartPoint:CGPointMake(0.5, 1.0)];
    [[self gradientLayer] setEndPoint:CGPointMake(0.5, 0.0)];
    [self.ownerButton.titleLabel wmf_applyDropShadow];
    [self.imageDescriptionLabel wmf_applyDropShadow];
}

- (IBAction)didTapOwnerButton
{
    if (self.ownerTapCallback) { self.ownerTapCallback(); }
}

@end
