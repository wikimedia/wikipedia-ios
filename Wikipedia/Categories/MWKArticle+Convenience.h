//  Created by Monte Hurd on 12/31/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKArticle.h"

@interface MWKArticle (Convenience)

// Untested.
- (MWKImage*)getFirstSectionImageLargerThanSize:(CGSize)size;

// Convenience method for saving an image not associated with
// any section, (such as a higher resolution variant of an
// image which is associated with a section).
- (MWKImage*)importImageURL:(NSString*)url
                  imageData:(NSData*)imageData;
@end
