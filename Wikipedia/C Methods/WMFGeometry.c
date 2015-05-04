//  Created by Monte Hurd on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFGeometry.h"
#include <CoreGraphics/CGAffineTransform.h>

/**
 *  http://stackoverflow.com/a/16042543/48311
 *
 */
CGRect WMFUnitRectWithReferenceRect(CGRect rect, CGRect referenceRect){
    if (CGRectIsEmpty(referenceRect) || CGRectIsEmpty(rect)) {
        return CGRectZero;
    }
    CGAffineTransform t = CGAffineTransformMakeScale(1.0f / referenceRect.size.width, 1.0f / referenceRect.size.height);
    CGRect unitRect = CGRectApplyAffineTransform(rect, t);
    return unitRect;
}

CGRect WMFRectWithUnitRectInReferenceRect(CGRect unitRect, CGRect referenceRect){
    if (CGRectIsEmpty(referenceRect) || CGRectIsEmpty(unitRect)) {
        return CGRectZero;
    }

    CGAffineTransform t = CGAffineTransformMakeScale(referenceRect.size.width, referenceRect.size.height);
    CGRect rect = CGRectApplyAffineTransform(unitRect, t);
    return rect;
}

CGRect WMFUnitRectFromRectForReferenceSize(CGRect rect, CGSize refSize){
    if (CGSizeEqualToSize(refSize, CGSizeZero) || CGRectIsEmpty(rect)) {
        return CGRectZero;
    }
    return CGRectMake(
                      CGRectGetMinX(rect) / refSize.width,
                      CGRectGetMinY(rect) / refSize.height,
                      CGRectGetWidth(rect) / refSize.width,
                      CGRectGetHeight(rect) / refSize.height
                      );
}

CGRect WMFRectFromUnitRectForReferenceSize(CGRect unitRect, CGSize refSize){
    return CGRectMake(
                      unitRect.origin.x * refSize.width,
                      unitRect.origin.y * refSize.height,
                      unitRect.size.width * refSize.width,
                      unitRect.size.height * refSize.height
                      );
}