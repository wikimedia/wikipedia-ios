//
//  MWKArticle+HTMLImageImport.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+HTMLImageImport.h"
#import "Defines.h"

#import <hpple/TFHpple.h>

#import "NSURL+WMFExtras.h"

#import "MWKImage.h"
#import "MWKImageList.h"
#import "MWKSectionList.h"
#import "MWKSection+HTMLImageExtraction.h"

@implementation MWKArticle (HTMLImageImport)

- (void)importAndSaveImagesFromSectionHTML {
    [self.sections.entries bk_each:^(MWKSection* section) {
        [self importAndSaveImagesFromSection:section];
    }];
}

- (void)importAndSaveImagesFromSection:(MWKSection*)section {
    for (TFHppleElement* imageNode in [section parseImageElements]) {
        [self importAndSaveImagesFromElement:imageNode intoSection:section.sectionId];
    }
}

- (void)importAndSaveImagesFromElement:(TFHppleElement*)imageNode intoSection:(int)sectionID {
    if (![imageNode.tagName isEqualToString:@"img"]) {
        DDLogWarn(@"Unexpected element type passed to image import: %@", imageNode.raw);
        return;
    }

    CGSize sizeToCheck = CGSizeZero;

    NSString* imgHeight = imageNode.attributes[@"height"];
    NSString* imgWidth  = imageNode.attributes[@"width"];
    CGSize size         = CGSizeZero;
    if ([imgWidth respondsToSelector:@selector(floatValue)] && [imgHeight respondsToSelector:@selector(floatValue)]) {
        size        = CGSizeMake([imgWidth floatValue], [imgHeight floatValue]);
        sizeToCheck = size;
    }

    NSString* fileWidth   = imageNode.attributes[@"data-file-height"];
    NSString* fileHeight  = imageNode.attributes[@"data-file-width"];
    CGSize fileDimensions = CGSizeZero;
    if ([fileWidth respondsToSelector:@selector(floatValue)] && [fileHeight respondsToSelector:@selector(floatValue)]) {
        fileDimensions = CGSizeMake([fileWidth floatValue], [fileHeight floatValue]);
        sizeToCheck    = fileDimensions;
    }

    if (![MWKImage isSizeLargeEnoughForGalleryInclusion:sizeToCheck]) {
        return;
    }

    /*
       Is estimated size even being used anymore?  Are we expecting it to be points or pixels?  Calculating pixels atm...
     */
    MWKImage*(^ imageWithEstimatedSizeAndURL)(NSURL* url, float scale) = ^MWKImage*(NSURL* srcURL, float scale) {
        if (srcURL.absoluteString.length == 0) {
            return nil;
        }
        MWKImage* image = [[MWKImage alloc] initWithArticle:self sourceURL:srcURL];
        if ([MWKImage fileSizePrefix:srcURL.absoluteString] != NSNotFound && [imgWidth respondsToSelector:@selector(integerValue)] && [imgHeight respondsToSelector:@selector(integerValue)]) {
            // don't add estimated width/height for images without a size prefix, since they're the original image
            image.width  = @(imgWidth.integerValue * scale);
            image.height = @(imgHeight.integerValue * scale);
        }

        if ([fileWidth respondsToSelector:@selector(integerValue)] && [fileHeight respondsToSelector:@selector(integerValue)]) {
            image.originalFileWidth  = @(fileWidth.integerValue);
            image.originalFileHeight = @(fileHeight.integerValue);
        }

        return image;
    };

    MWKImage* sourceImage =
        imageWithEstimatedSizeAndURL([NSURL wmf_optionalURLWithString:imageNode.attributes[@"src"]], 1);

    NSArray<MWKImage*>* allImages = sourceImage == nil ? @[] : @[sourceImage];

    for (MWKImage* image in allImages) {
        /*
           HAX: The MWK data layer is additive, in that articles can potentially accumulate old data over time, or that
              new images aren't added in the order we expect.  Ideally the image list as we've parsed it here becomes
              exactly the new image list, but atomic updates are tricky with a relational, file-system-based store.
              So, at this point we manually make sure to not accumulate images after multiple fetches, instead of
              taking care of it at a higher level.
         */
        [self appendImageListsWithSourceURL:image.sourceURLString inSection:sectionID skipIfPresent:YES];

        // save image metadata
        [image save];
    }
}

@end
