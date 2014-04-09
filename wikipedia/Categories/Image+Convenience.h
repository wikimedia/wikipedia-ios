//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Image.h"

@interface Image (Convenience)

// Retrieves the highest resolution image in the core data store with same name as this image.
-(Image *)getHighestResolutionImageWithSameNameUsingContext:(NSManagedObjectContext *)context;

@end
