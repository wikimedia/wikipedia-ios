//  Created by Monte Hurd on 6/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CoreDataHousekeeping.h"
#import "NSDate-Utilities.h"

@interface CoreDataHousekeeping (){
}

@end

@implementation CoreDataHousekeeping

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void)performHouseKeeping
{
    /*
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
     */
}

-(void)removeUnsavedUnhistoriedArticles
{
    /*
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
     */
}

@end
