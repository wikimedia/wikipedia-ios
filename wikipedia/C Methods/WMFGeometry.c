//  Created by Monte Hurd on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#include "WMFGeometry.h"

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