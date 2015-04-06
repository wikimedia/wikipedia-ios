// //  MWKImageGalleryCollectionViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryCollectionViewCell.h"
#import <BlocksKit/BlocksKit.h>
#import <Masonry/Masonry.h>

#import "WMFImageGalleryDetailOverlayView.h"
#import "UIView+WMFFrameUtils.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFGradientView.h"
#import "WMFRoundingUtilities.h"

static double const WMFImageGalleryMaxDetailHeight = 250.0;

@interface WMFImageGalleryCollectionViewCell ()
<UIScrollViewDelegate>
@property (nonatomic, weak, readonly) UIImageView* imageView;
@property (nonatomic, weak, readonly) UIScrollView* imageContainerView;
@property (nonatomic, weak, readonly) WMFGradientView* gradientView;

/**
 * Use this getter (instead of @c imageSize or <code>image.size</code>) to resolve the image size for display &
 * calculation purposes.
 * @return <code>imageSize</code>, or <code>image.size</code> if @c imageSize is <code>CGSizeZero</code>
 */
@property (nonatomic, readonly) CGSize effectiveImageSize;
@end

@implementation WMFImageGalleryCollectionViewCell
@synthesize imageSize = _imageSize;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.clipsToBounds = YES;

        _imageSize = CGSizeZero;

        UIScrollView* imageContainerView = [[UIScrollView alloc] init];
        imageContainerView.scrollsToTop                   = NO;
        imageContainerView.showsHorizontalScrollIndicator = NO;
        imageContainerView.showsVerticalScrollIndicator   = NO;
        imageContainerView.delegate                       = self;
        imageContainerView.bouncesZoom                    = YES;
        [self.contentView addSubview:imageContainerView];
        _imageContainerView = imageContainerView;

        UIImageView* imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.imageContainerView addSubview:imageView];
        _imageView = imageView;

        WMFGradientView* gradientView = [WMFGradientView new];
        [gradientView.gradientLayer setLocations:@[@0, @1]];
        [gradientView.gradientLayer setColors:@[(id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
                                                (id)[UIColor clearColor].CGColor]];
        // default start/end points, to be adjusted w/ image size
        [gradientView.gradientLayer setStartPoint:CGPointMake(0.5, 1.0)];
        [gradientView.gradientLayer setEndPoint:CGPointMake(0.5, 0.0)];
        gradientView.userInteractionEnabled = NO;
        [self.contentView addSubview:gradientView];
        _gradientView = gradientView;

        WMFImageGalleryDetailOverlayView* detailOverlayView = [WMFImageGalleryDetailOverlayView wmf_viewFromClassNib];
        detailOverlayView.userInteractionEnabled = NO;
        [self.contentView addSubview:detailOverlayView];
        _detailOverlayView = detailOverlayView;

        [self.detailOverlayView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.height.lessThanOrEqualTo(@(WMFImageGalleryMaxDetailHeight)).with.priorityHigh();
            make.leading.equalTo(self.contentView.mas_leading);
            make.trailing.equalTo(self.contentView.mas_trailing);
            make.bottom.equalTo(self.contentView.mas_bottom);
        }];

        [self.gradientView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.equalTo(self.contentView.mas_leading);
            make.trailing.equalTo(self.contentView.mas_trailing);
            make.bottom.equalTo(self.detailOverlayView.mas_bottom);
            make.top.equalTo(self.detailOverlayView.mas_top);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.detailOverlayView setImageDescription:nil];
    [self.detailOverlayView setLicense:nil owner:nil];
    self.gradientView.hidden                = NO;
    self.detailOverlayView.hidden           = NO;
    self.detailOverlayView.ownerTapCallback = nil;
    self.image                              = nil;
    self.imageSize                          = CGSizeZero;
    self.imageContainerView.contentOffset   = CGPointZero;
}

#pragma mark - Layout

// Called in response to events such as rotation or a new image being set.
- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.detailOverlayView.frame.size.height > 0.0) {
        // start gradient at the top of the image description label
        double const imageDescriptionTop =
            self.detailOverlayView.frame.size.height
            - self.detailOverlayView.imageDescriptionLabel.frame.origin.y;
        double const relativeImageDescriptionTop = 1.0 - imageDescriptionTop / self.detailOverlayView.frame.size.height;
        self.gradientView.gradientLayer.startPoint = CGPointMake(0.5, relativeImageDescriptionTop);
    }
    // zoomScale *must* be reset before applying new frames
    self.imageContainerView.minimumZoomScale = 1.f;
    self.imageContainerView.maximumZoomScale = 1.f;
    self.imageContainerView.zoomScale        = 1.f;

    /*
       the imageContainerView & image's frames are set manually because:
        1. the "pure" AutoLayout approach doesn't work on iOS 6, or at least, is broken when you try to do the
           contentInset & zoomScale stuff we're doing below.
        2. the imageView's size is set explicitly when an imageSize is provided, which prevents jumpy frames when
           setting higher-resolution images.
       for more info, see Apple TN2154 for Apple's recommendations on how to use a UIScrollView w/ auto layout:
       https://developer.apple.com/library/ios/technotes/tn2154/_index.html
     */
    self.imageContainerView.frame       = self.contentView.bounds;
    self.imageContainerView.contentSize = self.contentView.bounds.size;
    self.imageView.frame                = (CGRect){
        .origin = CGPointZero,
        .size   = self.effectiveImageSize
    };

    // once frames are set, transforms & insets can be applied
    [self resetScaleFactors];
    [self centerImageInScrollView];
}

#pragma mark - View Updates

/**
 * Apply a contentInset to the scrollView such that the image appears in the center. This guarantees proper
 * zooming and panning behavior.
 * @warning This must be called after zoom scales are set, as it relies on the scroll view's current @c zoomScale.
 */
- (void)centerImageInScrollView {
    if (!self.image) {
        self.imageContainerView.contentInset = UIEdgeInsetsZero;
        return;
    }
    CGSize currentImageSize = CGSizeMake(self.effectiveImageSize.width * self.imageContainerView.zoomScale,
                                         self.effectiveImageSize.height * self.imageContainerView.zoomScale);
    double const horizontalPadding =
        fmax(0.0, floor((self.contentView.frame.size.width - currentImageSize.width) / 2.0));
    double const verticalPadding =
        fmax(0.0, floor((self.contentView.frame.size.height - currentImageSize.height) / 2.0));
    UIEdgeInsets newInsets = UIEdgeInsetsMake(verticalPadding,
                                              horizontalPadding,
                                              verticalPadding,
                                              horizontalPadding);
    self.imageContainerView.contentInset = newInsets;
}

/**
 * Set the min/max/current @c zoomScale for <code>imageContainerView</code>. See implementation comments for details.
 * @note This is invoked automatically by @c centerImageInScrollView
 */
- (void)resetScaleFactors {
    if (self.image) {
        // img dimension * scale = container bounds dimension, solve for scale
        double const widthScale  = self.contentView.frame.size.width / self.effectiveImageSize.width;
        double const heightScale = self.contentView.frame.size.height / self.effectiveImageSize.height;
        /*
           The minimum & maximum scales need to be rounded *down*, otherwise there's an "off by one" error where the
           contents of @c imageContainerView are _just_ larger than its @c contentSize, which causes paging glitches.
         */
        double const minScale = FlooredPercentage(fmin(widthScale, heightScale));

        // images should be zoomable up to, at most, twice their intrinsic content size
        // in cases where the image is small, and minScale > 1, we must make sure maxScale >= minScale
        double const maxScale = fmax(minScale, FlooredPercentage(2.0 / minScale));

        NSParameterAssert(minScale <= maxScale);
        self.imageContainerView.minimumZoomScale = minScale;
        self.imageContainerView.maximumZoomScale = maxScale;
    } else {
        self.imageContainerView.minimumZoomScale = 1.0;
        self.imageContainerView.maximumZoomScale = 1.0;
    }
    self.imageContainerView.zoomScale = self.imageContainerView.minimumZoomScale;
}

#pragma mark - Getters & Setters

- (UIImage*)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage*)image {
    if (self.image == image || [self.image isEqual:image]) {
        return;
    }
    self.imageView.image = image;
    // background color is set here to prevent "white flashes" while setting image
    self.imageView.backgroundColor = image ? [UIColor whiteColor] : [UIColor clearColor];
    [self setNeedsLayout];
}

- (CGSize)effectiveImageSize {
    return CGSizeEqualToSize(_imageSize, CGSizeZero) ? self.image.size : _imageSize;
}

- (void)setImageSize:(CGSize)imageSize {
    if (CGSizeEqualToSize(self.effectiveImageSize, imageSize)) {
        return;
    }
    _imageSize = imageSize;
    [self setNeedsLayout];
}

- (void)setDetailViewAlpha:(float)alpha {
    self.gradientView.alpha = alpha;
    [self.detailOverlayView setGroupAlpha:alpha];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView*)scrollView {
    // image must be re-centered since the scrollView zoom affects offsets _and_ size
    [self centerImageInScrollView];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView*)imageScrollView {
    return self.imageView;
}

@end
