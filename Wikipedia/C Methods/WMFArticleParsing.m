//
//  WMFArticleParsing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleParsing.h"
#import <hpple/TFHpple.h>
#import "MWKImage.h"
#import "MWKArticle.h"
#import "Defines.h"

NSString* WMFImgTagsFromHTML(NSString* html) {
    if (html.length == 0) {
        return @"";
    }
    static NSRegularExpression* regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"<img\\s+[^>]*>" options:0 error:nil];
    });
    NSArray* matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
    if (matches.count == 0) {
        return @"";
    }
    NSMutableArray* output = [NSMutableArray arrayWithCapacity:matches.count];
    NSInteger i            = 0;
    for (NSTextCheckingResult* result in matches) {
        output[i++] = [html substringWithRange:result.range];
    }
    return [output componentsJoinedByString:@""];
}

void WMFInjectArticleWithImagesFromSection(MWKArticle* article, NSString* sectionHTML, int sectionID) {
    // Reduce to img tags only. Causes TFHpple parse time to drop by ~50%.
    NSString* sectionImageTags = WMFImgTagsFromHTML(sectionHTML);

    if (sectionImageTags.length == 0 || !article) {
        return;
    }
    // Parse the section html extracting the image urls (in order)
    // See: http://www.raywenderlich.com/14172/how-to-parse-html-on-ios
    // for TFHpple details.

    // Call *after* article record created but before section html sent across bridge.
    TFHpple* sectionParser = [TFHpple hppleWithHTMLData:[sectionImageTags dataUsingEncoding:NSUTF8StringEncoding]];
    NSArray* imageNodes    = [sectionParser searchWithXPathQuery:@"//img[@src]"];

    BOOL isRetinaAndAtLeastiOS8Device = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) && ([UIScreen mainScreen].scale > 1.0f);

    for (TFHppleElement* imageNode in imageNodes) {
        NSString* imgHeight = imageNode.attributes[@"height"];
        if (imgHeight.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height) {
            continue;
        }
        NSString* imgWidth = imageNode.attributes[@"width"];
        if (imgWidth.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width) {
            continue;
        }

        NSString* srcTagImageURL = imageNode.attributes[@"src"];
        NSInteger density        = 1;

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
        if (isRetinaAndAtLeastiOS8Device) {
            for (NSString* subSrc in [imageNode.attributes[@"srcset"] componentsSeparatedByString:@","]) {
                NSString* trimmed =
                    [subSrc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSArray* parts = [trimmed componentsSeparatedByString:@" "];
                if (parts.count == 2 && [parts[1] isEqualToString:@"2x"]) {
                    // Quick hack to shortcut relevant syntax :P
                    srcTagImageURL = parts[0];
                    density        = 2;
                    break;
                }
            }
        }

        MWKImage* image = [article importImageURL:srcTagImageURL sectionId:sectionID];

        // If img tag dimensions were extracted, save them so they don't have to be expensively determined later.
        if (imgWidth && imgHeight) {
            // Don't record dimensions if image file name doesn't have size prefix.
            // (Sizes from the img tag don't tend to correspond closely to actual
            // image binary sizes for these.)
            if ([MWKImage fileSizePrefix:srcTagImageURL] != NSNotFound) {
                image.width  = @(imgWidth.integerValue * density);
                image.height = @(imgHeight.integerValue * density);
            }
        }

        [image save];
    }
}

