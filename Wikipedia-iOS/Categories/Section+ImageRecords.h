//  Created by Monte Hurd on 1/15/14.

#import "Section.h"

@interface Section (ImageRecords)

// Parses the section's html looking for image tags and creates core data
// images objects. When the web view starts downloading these images the
// URLCache object can then associate the images (via their url) to these
// core data image objects.
-(void)createImageRecordsForHtmlOnContext:(NSManagedObjectContext *)context;

@end
