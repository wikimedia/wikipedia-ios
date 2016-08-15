//
//  UIImageView+WMFContentOffset.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImageView+WMFContentOffset.h"
#import "WMFMath.h"
#import "UIImage+WMFNormalization.h"
#import "WMFGeometry.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImageView (WMFContentOffset)

- (void)wmf_cropContentsByVerticallyCenteringFrame:(CGRect)rect
                               insideBoundsOfImage:(UIImage *)image {
    CGRect verticallyCenteredFrame = CGRectMake(0,
                                                rect.origin.y,
                                                image.size.width,
                                                rect.size.height);
    [self wmf_cropContentsToFrame:verticallyCenteredFrame insideBoundsOfImage:image];
}

- (void)wmf_cropContentsToFrame:(CGRect)rect insideBoundsOfImage:(UIImage *)image {
    CGPoint rectCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGPoint imageCenter = CGPointMake(image.size.width / 2.f, image.size.height / 2.f);

    CGPoint offset = CGPointZero;
    offset.x = rectCenter.x - imageCenter.x;
    offset.y = rectCenter.y - imageCenter.y;

    [self wmf_setContentOffset:offset image:image];
}

- (void)wmf_setContentOffset:(CGPoint)offset image:(UIImage *)image {
    self.layer.contentsRect = [image wmf_normalizeRect:
                                         CGRectMake(WMFClamp(0, offset.x, image.size.width),
                                                    WMFClamp(0, offset.y, image.size.height),
                                                    image.size.width - fabs(offset.x * 2.f),
                                                    image.size.height - fabs(offset.y * 2.f))];
}

- (void)wmf_resetContentsRect {
    self.layer.contentsRect = CGRectMake(0, 0, 1, 1);
}

@end

NS_ASSUME_NONNULL_END
