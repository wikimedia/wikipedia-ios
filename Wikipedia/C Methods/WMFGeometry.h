//  Created by Monte Hurd on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#ifndef __Wikipedia__WMFGeometry__
#define __Wikipedia__WMFGeometry__

#import <stdio.h>

#import <CoreGraphics/CGGeometry.h>

// Convert rect to a unit rect for reference size.
CG_EXTERN CGRect WMFUnitRectFromRectForReferenceSize(CGRect rect, CGSize referenceSize);

// Convert unit rect back to rect for reference size.
CG_EXTERN CGRect WMFRectFromUnitRectForReferenceSize(CGRect unitRect, CGSize referenceSize);

#endif /* defined(__Wikipedia__WMFGeometry__) */
