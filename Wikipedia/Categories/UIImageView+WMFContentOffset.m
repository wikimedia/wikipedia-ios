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

@implementation UIImageView (WMFContentOffset)

- (void)wmf_setContentOffsetToCenterFeature:(CIFeature* __nullable)feature {
    if (feature) {
        [self wmf_setContentOffsetToCenterRect:[self.image wmf_normalizeAndConvertCGCoordinateRect:feature.bounds]];
    }
}

- (void)wmf_setContentOffsetToCenterRect:(CGRect)rect {
    CGPoint rectCenter  = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGPoint imageCenter = CGPointMake(self.image.size.width / 2.f, self.image.size.height / 2.f);

    CGPoint offset = CGPointZero;
    offset.x = rectCenter.x - imageCenter.x;
    offset.y = rectCenter.y - imageCenter.y;

    [self wmf_setContentOffset:offset];
}

- (void)wmf_setContentOffset:(CGPoint)offset {
    self.layer.contentsRect = [self.image wmf_normalizeRect:
                               CGRectMake(WMFClamp(0, offset.x, self.image.size.width),
                                          WMFClamp(0, offset.y, self.image.size.height),
                                          self.image.size.width - fabs(offset.x * 2.f),
                                          self.image.size.height - fabs(offset.y * 2.f))];
}

- (void)wmf_resetContentOffset {
    self.layer.contentsRect = CGRectMake(0, 0, 1, 1);
}

@end
