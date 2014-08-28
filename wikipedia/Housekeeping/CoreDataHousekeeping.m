//  Created by Monte Hurd on 6/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CoreDataHousekeeping.h"
#import "NSDate-Utilities.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"

@interface CoreDataHousekeeping (){
    NSManagedObjectContext *context_;
}

@end

@implementation CoreDataHousekeeping

- (instancetype)init
{
    self = [super init];
    if (self) {
        context_ = [ArticleDataContextSingleton sharedInstance].mainContext;
    }
    return self;
}

-(void)performHouseKeeping
{
    [context_ performBlockAndWait:^(){
        
        [self removeUnsavedUnhistoriedArticles];
        [self removeUnsavedArticleSections];

        NSError *error = nil;
        [context_ save:&error];
        if (error){
            NSLog(@"ImageHousekeeping error = %@", error);
        }else{
            [self removeUnusedImages];
            
            error = nil;
            [context_ save:&error];
            if (error) NSLog(@"ImageHousekeeping error = %@", error);
        }

    }];
}

-(void)removeUnsavedUnhistoriedArticles
{
    // Removes articles which have neither saved nor history records.
    // The user can remove items from both saved pages and history.
    // If they've removed this article from both, not need to keep its
    // data.

    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Article" inManagedObjectContext: context_];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    // To-many query: http://stackoverflow.com/a/1195519
    [request setPredicate:[NSPredicate predicateWithFormat:@"history.@count == 0 AND saved.@count == 0"]];
    
    NSError *error = nil;
    NSArray *articles = [context_ executeFetchRequest:request error:&error];
    for (Article *article in articles) {
        NSLog(@"removing article w/o history or save records = %@", article.title);
        if (article) [context_ deleteObject:article];
    }
}

-(void)removeUnsavedArticleSections
{
    // Removes article sections for articles which are unsaved, but which still have a history record.
    
    // This way the history items will still work if tapped - they will re-download their section data
    // automatically because we also set "needsRefresh" to YES below. Also, by removing these sections,
    // the "removeUnusedImages" should be able to clean up more images (unused images, that is,
    // unreferenced by any sections, are removed by removeUnusedImages).

    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Article" inManagedObjectContext: context_];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    // To-many query: http://stackoverflow.com/a/1195519
    [request setPredicate:[NSPredicate predicateWithFormat:@"history.@count > 0 AND saved.@count == 0"]];
    
    NSError *error = nil;
    NSArray *articles = [context_ executeFetchRequest:request error:&error];
    for (Article *article in articles) {
        NSLog(@"removing sections from article w history w/o saved record = %@", article.title);
        for (Section *section in article.section) {
            if (section) [context_ deleteObject:section];
        }
        article.needsRefresh = @YES;
    }
}

-(void)removeUnusedImages
{
    // Remove core data Images which are not associated with either a SectionImage record or an Article record's
    // "thumbnailImage" property.
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Image" inManagedObjectContext: context_];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];

    // To-many query: http://stackoverflow.com/a/1195519 (the "@" part).
    // Reminder that "article.@count" tells us if any article record "thumbnailImage" property is referencing
    // this image.
    [request setPredicate:[NSPredicate predicateWithFormat:@"sectionImage.@count == 0 AND article.@count == 0"]];
    
    NSError *error = nil;
    NSArray *images = [context_ executeFetchRequest:request error:&error];
    for (Image *image in images) {
        NSLog(@"unused image = %@", image.fileName);
        if (image) [context_ deleteObject:image];
    }
}

@end
