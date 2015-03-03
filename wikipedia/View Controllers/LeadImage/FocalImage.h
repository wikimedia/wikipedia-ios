//  Created by Monte Hurd on 12/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface FocalImage : UIImage

/*
   This draws image with:

    - Aspect fill.
    - Horizontal center if horizontal overlap.
    - Align top if no focalBounds, else vertical centered on focalBounds.
    - Optional focalBounds highlight.
 */
- (void)drawInRect:(CGRect)rect
       focalBounds:(CGRect)focalBounds
    focalHighlight:(BOOL)focalHighlight
         blendMode:(CGBlendMode)blendMode
             alpha:(CGFloat)alpha;

// Repeated calls to "getFaceBounds" will return the next face
// rect each time (rolling back to first face after last face).
- (CGRect)getFaceBounds;

@end
