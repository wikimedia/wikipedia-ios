//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKSection+ImageRecords.h"
#import "TFHpple.h"
#import "Defines.h"
#import "NSString+Extras.h"

@implementation MWKSection (ImageRecords)

-(void)createImageRecordsForHtmlOnArticleStore:(MWKArticleStore *)articleStore
{
    // Parse the section html extracting the image urls (in order)
    // See: http://www.raywenderlich.com/14172/how-to-parse-html-on-ios
    // for TFHpple details.
    
    // Call *after* article record created but before section html sent across bridge.
    
    // Reminder: don't do "context performBlockAndWait" here - createImageRecordsForHtmlOnContext gets
    // called in a loop which is encompassed by such a block already!
    
    NSString *html = [articleStore sectionTextAtIndex:self.sectionId];
    if (html.length == 0) return;
    
    NSData *sectionHtmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *sectionParser = [TFHpple hppleWithHTMLData:sectionHtmlData];
    //NSString *imageXpathQuery = @"//img[@src]";
    NSString *imageXpathQuery = @"//img[@src][not(ancestor::table[@class='navbox'])]";
    // ^ the navbox exclusion prevents images from the hidden navbox table from appearing
    // in the last section's TOC cell.
    
    NSArray *imageNodes = [sectionParser searchWithXPathQuery:imageXpathQuery];
    NSUInteger imageIndexInSection = 0;
    
    for (TFHppleElement *imageNode in imageNodes) {
        
        NSString *height = imageNode.attributes[@"height"];
        NSString *width = imageNode.attributes[@"width"];
        
        if (
            height.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width
            ||
            width.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height
            )
        {
            //NSLog(@"SKIPPING - IMAGE TOO SMALL");
            continue;
        }
        
        NSString *alt = imageNode.attributes[@"alt"];
        NSString *src = imageNode.attributes[@"src"];
        int density = 1;

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
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            if ([UIScreen mainScreen].scale > 1.0f) {
                NSString *srcSet = imageNode.attributes[@"srcset"];
                for (NSString *subSrc in [srcSet componentsSeparatedByString:@","]) {
                    NSString *trimmed = [subSrc stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
                    NSArray *parts = [trimmed componentsSeparatedByString:@" "];
                    if (parts.count == 2 && [parts[1] isEqualToString:@"2x"]) {
                        // Quick hack to shortcut relevant syntax :P
                        src = parts[0];
                        density = 2;
                        break;
                    }
                }
            }
        }
        
        MWKImage *image = [articleStore imageWithURL:src];
        
        if (image) {
            // If Image record already exists, update its attributes.
            //image.alt = alt;
            //image.height = @(height.integerValue * density);
            //image.width = @(width.integerValue * density);
        }else{
            // If no Image record, create one setting its "data" attribute to nil. This allows the record to be
            // created so it can be associated with the section in which this , then when the URLCache intercepts the request for this image
            image = [articleStore importImageURL:src];
        }
        
        // If imageSection doesn't already exist with the same index and image, create sectionImage record
        // associating the image record (from line above) with section record and setting its index to the
        // order from img tag parsing.
        /*
        SectionImage *sectionImage = (SectionImage *)[context getEntityForName: @"SectionImage"
                                                           withPredicateFormat: @"section == %@ AND index == %@ AND image.sourceUrl == %@",
                                                      self, @(imageIndexInSection), src
                                                      ];
        if (!sectionImage) {
            sectionImage = [NSEntityDescription insertNewObjectForEntityForName:@"SectionImage" inManagedObjectContext:context];
            sectionImage.image = image;
            sectionImage.index = @(imageIndexInSection);
            sectionImage.section = self;
        }
        imageIndexInSection ++;
         */
    }
    
    // Reminder: don't do "context save" here - createImageRecordsForHtmlOnContext gets
    // called in a loop after which save is called. This method *only* creates - the caller
    // is responsible for saving.
}

@end
