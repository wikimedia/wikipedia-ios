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

    NSString* imgHeight = imageNode.attributes[@"data-file-height"] ? : imageNode.attributes[@"height"];
    NSString* imgWidth  = imageNode.attributes[@"data-file-width"] ? : imageNode.attributes[@"width"];

    CGSize size = CGSizeMake([imgWidth floatValue], [imgHeight floatValue]);
    if (![MWKImage isSizeLargeEnoughForGalleryInclusion:size]) {
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
        if ([MWKImage fileSizePrefix:srcURL.absoluteString] != NSNotFound) {
            // don't add estimated width/height for images without a size prefix, since they're the original image
            image.width  = @(imgWidth.integerValue * scale);
            image.height = @(imgHeight.integerValue * scale);
        }
        return image;
    };

    MWKImage* sourceImage =
        imageWithEstimatedSizeAndURL([NSURL wmf_optionalURLWithString:imageNode.attributes[@"src"]], 1);

    NSArray<MWKImage*>* srcsetImages = [[[imageNode.attributes[@"srcset"] componentsSeparatedByString:@","] bk_map:^id (NSString* srcsetComponent) {
        NSArray* srcsetComponentParts =
            [[srcsetComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
             componentsSeparatedByString:@" "];
        NSURL* url = [NSURL wmf_optionalURLWithString:srcsetComponentParts.firstObject];
        float scale = 1;
        if (srcsetComponentParts.count == 2) {
            NSScanner* scaleSuffixScanner = [NSScanner scannerWithString:srcsetComponentParts[1]];
            float scannedSuffixValue = 0.f;
            if ([scaleSuffixScanner scanFloat:&scannedSuffixValue]) {
                // iOS devices don't use fractional scales, so round them down (e.g. 1.5x becomes 1x)
                scale = floor(scannedSuffixValue);
            } else {
                DDLogInfo(@"Failed to scale srcset scale suffix of component: %@", srcsetComponent);
            }
        }
        return imageWithEstimatedSizeAndURL(url, scale);
    }] bk_reject:^BOOL (id obj) {
        return [NSNull null] == obj;
    }];

    // group src & srset images together, handling case where there was no srcset attribute
    NSMutableArray<MWKImage*>* allImages = [(srcsetImages ? : @[]) mutableCopy];
    if (sourceImage) {
        [allImages insertObject:sourceImage atIndex:0];
    }

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
