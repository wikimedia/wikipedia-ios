// //  MWKImageGalleryCollectionViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryCollectionViewCell.h"
#import "WMFImageGalleryDetailOverlayView.h"
#import <BlocksKit/BlocksKit.h>

@interface WMFImageGalleryCollectionViewCell ()
<UIScrollViewDelegate>
@property (nonatomic, weak, readonly) UIImageView* imageView;
@property (nonatomic, weak, readonly) UIScrollView* imageContainerView;
@end

@implementation WMFImageGalleryCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView.backgroundColor = [UIColor clearColor];

        // image view's frame fills the scroll view's *bounds*, and zooming transforms it to the natural image size
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode     = UIViewContentModeScaleAspectFit;
        _imageView                = imageView;

        // scroll view fills content view's bounds
        UIScrollView* imageScrollView = [[UIScrollView alloc] initWithFrame:self.contentView.bounds];
        imageScrollView.delegate = self;
        _imageContainerView      = imageScrollView;

        // scroll view & image view layout is done programmatically
        [imageScrollView addSubview:imageView];
        [self.contentView addSubview:imageScrollView];

        // detail overlay has a fixed height, set at the bottom of the content view, above the scroll view
        NSNumber* detailHeight                              = @150.f;
        WMFImageGalleryDetailOverlayView* detailOverlayView =
            [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([WMFImageGalleryDetailOverlayView class])
                                           owner:nil
                                         options:nil] firstObject];

        NSParameterAssert(detailOverlayView);
        detailOverlayView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:detailOverlayView];
        _detailOverlayView = detailOverlayView;

        [self.contentView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[detailOverlayView(<=detailHeight@1000)]|"
                                                 options:0
                                                 metrics:NSDictionaryOfVariableBindings(detailHeight)
                                                   views:NSDictionaryOfVariableBindings(detailOverlayView)]];

        [self.contentView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[detailOverlayView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(detailOverlayView)]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.image                                        = nil;
    self.detailOverlayView.imageDescriptionLabel.text = nil;
    [self.detailOverlayView.ownerButton setAttributedTitle:nil forState:UIControlStateNormal];
    self.detailOverlayView.hidden           = YES;
    self.detailOverlayView.ownerTapCallback = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // scroll view zoom must be reset before resizing
    // TODO: find current zoom rect and re-zoom to it once new max is set
    self.imageContainerView.zoomScale = 1.f;

    // set scroll view & image view to fill content view
    self.imageContainerView.frame       = self.contentView.bounds;
    self.imageContainerView.contentSize = self.contentView.bounds.size;
    self.imageView.frame                = self.imageContainerView.bounds;

    if (self.imageView.image) {
        // max zoom * imageView.bounds.size = image.size
        float const containerToNaturalWidthScale =
            self.image.size.width / self.contentView.bounds.size.width;
        float const containterToNaturalHeightScale =
            self.image.size.height / self.contentView.bounds.size.height;
        // max zoom scale should never be < min zoom scale (1)
        self.imageContainerView.maximumZoomScale =
            fmaxf(1.f, fmaxf(containerToNaturalWidthScale, containterToNaturalHeightScale));
    } else {
        self.imageContainerView.maximumZoomScale = 1.0;
    }

    self.imageContainerView.contentOffset = CGPointZero;
    self.imageContainerView.zoomScale     = self.imageContainerView.minimumZoomScale;
}

#pragma mark - Getters & Setters

- (UIImage*)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage*)image {
    if (self.imageView.image == image || [self.imageView.image isEqual:image]) {
        return;
    }
    self.imageView.image = image;
    [self setNeedsLayout];
}

#pragma mark - UIScrollViewDelegate

- (UIView*)viewForZoomingInScrollView:(UIScrollView*)imageScrollView {
    return self.imageView;
}

@end
