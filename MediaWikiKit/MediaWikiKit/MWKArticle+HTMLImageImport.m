//
//  MWKArticle+HTMLImageImport.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+HTMLImageImport.h"
#import "MWKSection.h"
#import "MWKImage.h"
#import "MWKImageList.h"
#import "MWKSectionList.h"
#import <hpple/TFHpple.h>
#import "Defines.h"
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

    NSString* imgHeight = imageNode.attributes[@"height"];

    if (imgHeight && imgHeight.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height) {
        return;
    }
    NSString* imgWidth = imageNode.attributes[@"width"];
    if (imgWidth && imgWidth.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width) {
        return;
    }

    NSString* srcURL  = imageNode.attributes[@"src"];
    NSInteger density = 1;


    BOOL const isRetina = [UIScreen mainScreen].scale > 1.0f;

    // This is a horrible hack to compensate for iOS 8 WebKit's srcset
    // handling and the way we currently handle image caching which
    // doesn't quite handle that right.
    //
    // WebKit on iOS 8 and later understands the new img 'srcset' attribute
    // which can provide alternate-resolution versions for different device
    // pixel ratios (and in theory some other size-based alternates, but we
    // don't use that stuff). MediaWiki/Wikipedia uses this to specify image
    // versions at 1.5x and 2x density levels, which the browser should use
    // as appropriate in preference to the 'src' URL which is assumed to be
    // at 1x density.
    //
    // On iOS 7 and earlier, or on non-Retina devices on iOS 8, the 1x image
    // URL from the 'src' attribute is still used as-is.
    //
    // By making sure we pick the same version that WebKit will pick up later,
    // here we ensure that the correct entries will be cached.
    //
    if (isRetina) {
        for (NSString* subSrc in [imageNode.attributes[@"srcset"] componentsSeparatedByString:@","]) {
            NSString* trimmed =
                [subSrc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray* parts = [trimmed componentsSeparatedByString:@" "];
            if (parts.count == 2 && [parts[1] isEqualToString:@"2x"]) {
                // Quick hack to shortcut relevant syntax :P
                srcURL  = parts[0];
                density = 2;
                break;
            }
        }
    }

    if (![self.images hasImageURL:[NSURL URLWithString:srcURL]]) {
        MWKImage* image = [self importImageURL:srcURL sectionId:sectionID];

        // If img tag dimensions were extracted, save them so they don't have to be expensively determined later.
        if (imgWidth && imgHeight) {
            // Don't record dimensions if image file name doesn't have size prefix.
            // (Sizes from the img tag don't tend to correspond closely to actual
            // image binary sizes for these.)
            if ([MWKImage fileSizePrefix:srcURL] != NSNotFound) {
                image.width  = @(imgWidth.integerValue * density);
                image.height = @(imgHeight.integerValue * density);
            }
        }

        [image save];
    }
}

@end
