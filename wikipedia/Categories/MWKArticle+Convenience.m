//  Created by Monte Hurd on 12/31/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKArticle+Convenience.h"

@implementation MWKArticle (Convenience)

-(MWKImage *)getFirstSectionImageLargerThanSize:(CGSize)size
{
    MWKImage *soughtImage = nil;
    for (MWKImage *image in self.images) {
        if (
            (image.width.floatValue >= size.width)
            &&
            (image.height.floatValue >= size.height)
        ) {
            soughtImage = image;
            break;
        }
    }
    return soughtImage;
}

@end
