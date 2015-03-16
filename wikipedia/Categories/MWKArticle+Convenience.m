//  Created by Monte Hurd on 12/31/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKArticle+Convenience.h"

@implementation MWKArticle (Convenience)

- (MWKImage*)getFirstSectionImageLargerThanSize:(CGSize)size {
    MWKImage* soughtImage = nil;
    for (MWKImage* image in self.images) {
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

- (MWKImage*)importImageURL:(NSString*)url
                  imageData:(NSData*)imageData {
    MWKImage* image = [self importImageURL:url
                                 sectionId:kMWKArticleSectionNone];

    [image importImageData:imageData];
    [image save];

    // MWKArticle's "save" causes its "images" list to be saved.
    [self save];

    return image;
}

@end
