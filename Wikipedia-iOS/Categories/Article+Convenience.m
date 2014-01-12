//  Created by Monte Hurd on 12/23/13.

#import "Article+Convenience.h"
#import "ArticleCoreDataObjects.h"
#import "Defines.h"

@implementation Article (Convenience)

-(NSArray *)getSectionImagesUsingContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"section.article == %@ AND (image.width >= %@ OR image.height >= %@)", self, @(THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width), @(THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height)];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"SectionImage"
                                              inManagedObjectContext: context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    // Sort by section.
    NSSortDescriptor *sectionSort = [[NSSortDescriptor alloc] initWithKey:@"section.index" ascending:YES selector:nil];
    // Within section sort by index.
    NSSortDescriptor *imageSort = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:nil];
    [fetchRequest setSortDescriptors:@[sectionSort, imageSort]];
    
    NSError *error = nil;
    NSArray *sectionImages = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error = %@", error);
    }
    return sectionImages;
}

-(NSArray *)getSectionsUsingContext:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"article == %@", self];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Section"
                                              inManagedObjectContext: context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    // Sort by section.
    NSSortDescriptor *sectionSort = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:nil];
    [fetchRequest setSortDescriptors:@[sectionSort]];
    
    NSError *error = nil;
    NSArray *sections = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error = %@", error);
    }
    return sections;
}

-(UIImage *)getThumbnailUsingContext:(NSManagedObjectContext *)context
{
    if(self.thumbnailImage){
        return [UIImage imageWithData:self.thumbnailImage.imageData.data];
    }else{
        NSArray *firstSectionImage = [self getFirstSectionImageLargerThanSize:THUMBNAIL_MINIMUM_SIZE_TO_CACHE usingContext:context];
        if (firstSectionImage.count == 1) {
            SectionImage *sectionImage = (SectionImage *)firstSectionImage[0];
            return [UIImage imageWithData:sectionImage.image.imageData.data];
        }
    }
    return nil;
}

-(NSArray *)getFirstSectionImageLargerThanSize:(CGSize)size usingContext:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"section.article == %@ AND image.width >= %@ AND image.height >= %@", self, @(size.width), @(size.height)];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"SectionImage"
                                              inManagedObjectContext: context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *sectionImages = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error = %@", error);
    }
    return sectionImages;
}

@end
