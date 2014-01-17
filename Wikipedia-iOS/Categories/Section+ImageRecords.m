//  Created by Monte Hurd on 1/15/14.

#import "Section+ImageRecords.h"
#import "TFHpple.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "NSString+Extras.h"

@implementation Section (ImageRecords)

-(void)createImageRecordsForHtmlOnContext:(NSManagedObjectContext *)context
{
    // Parse the section html extracting the image urls (in order)
    // See: http://www.raywenderlich.com/14172/how-to-parse-html-on-ios
    // for TFHpple details.
    
    // Call *after* article record created but before section html sent across bridge.

    NSManagedObjectID *sectionID = self.objectID;

    [context performBlockAndWait:^(){
        Section *section = (Section *)[context objectWithID:sectionID];
        
        NSData *sectionHtmlData = [section.html dataUsingEncoding:NSUTF8StringEncoding];
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

            Image *image = (Image *)[context getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", src];
            
            if (image) {
                // If Image record already exists, update its attributes.
                image.alt = alt;
                image.height = @(height.integerValue);
                image.width = @(width.integerValue);
            }else{
                // If no Image record, create one setting its "data" attribute to nil. This allows the record to be
                // created so it can be associated with the section in which this , then when the URLCache intercepts the request for this image
                image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];

                /*
                 Moved imageData into own entity:
                    "For small to modest sized BLOBs (and CLOBs), you should create a separate
                    entity for the data and create a to-one relationship in place of the attribute."
                    See: http://stackoverflow.com/a/9288796/135557
                 
                 This allows core data to lazily load the image blob data only when it's needed.
                 */
                image.imageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];

                image.imageData.data = [[NSData alloc] init];
                image.dataSize = @(image.imageData.data.length);
                image.fileName = [src lastPathComponent];
                image.fileNameNoSizePrefix = [image.fileName getWikiImageFileNameWithoutSizePrefix];
                image.extension = [src pathExtension];
                image.imageDescription = nil;
                image.sourceUrl = src;
                image.dateRetrieved = [NSDate date];
                image.dateLastAccessed = [NSDate date];
                image.width = @(width.integerValue);
                image.height = @(height.integerValue);
                image.mimeType = [image.extension getImageMimeTypeForExtension];
            }
            
            // If imageSection doesn't already exist with the same index and image, create sectionImage record
            // associating the image record (from line above) with section record and setting its index to the
            // order from img tag parsing.
            SectionImage *sectionImage = (SectionImage *)[context getEntityForName: @"SectionImage"
                                                                       withPredicateFormat: @"section == %@ AND index == %@ AND image.sourceUrl == %@",
                                      section, @(imageIndexInSection), src
                                      ];
            if (!sectionImage) {
                sectionImage = [NSEntityDescription insertNewObjectForEntityForName:@"SectionImage" inManagedObjectContext:context];
                sectionImage.image = image;
                sectionImage.index = @(imageIndexInSection);
                sectionImage.section = section;
            }
            imageIndexInSection ++;
        }

        NSError *error = nil;
        [context save:&error];
        if (error) {
            NSLog(@"\n\nerror = %@\n\n", error);
            NSLog(@"\n\nerror = %@\n\n", error.localizedDescription);
        }
    }];
}

@end
