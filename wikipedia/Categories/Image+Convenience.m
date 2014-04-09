//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Image+Convenience.h"

@implementation Image (Convenience)

-(Image *)getHighestResolutionImageWithSameNameUsingContext:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"fileNameNoSizePrefix == %@", self.fileNameNoSizePrefix];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Image"
                                              inManagedObjectContext: context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];

    NSSortDescriptor *widthSort = [[NSSortDescriptor alloc] initWithKey:@"width" ascending:NO selector:nil];
    [fetchRequest setSortDescriptors:@[widthSort]];

    NSError *error = nil;
    NSArray *images = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error = %@", error);
        return self;
    }
    return (images.count == 1) ? images[0] : self;
}

@end
