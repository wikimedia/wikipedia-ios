//  Created by Monte Hurd on 4/25/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ArticleImporter.h"

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "SavedPagesFunnel.h"

@implementation ArticleImporter

- (void)importArticles:(NSArray*)articleDictionaries {
    /*
       NSManagedObjectContext *context =
        [ArticleDataContextSingleton sharedInstance].mainContext;

       [context performBlock:^{

        SavedPagesFunnel *funnel = [[SavedPagesFunnel alloc] init];
        NSError *error = nil;
        for (NSDictionary *articleDict in articleDictionaries) {

            // Ensure both lang and title keys are present in this article dict.
            if (![articleDict objectForKey:@"lang"] || ![articleDict objectForKey:@"title"]){
                NSLog(@"Error: lang or title missing.");
                continue;
            }

            NSString *title = articleDict[@"title"];
            NSString *lang = articleDict[@"lang"];

            // Ensure both lang and title strings are not zero length.
            if ((title.length == 0) || (lang.length == 0)){
                NSLog(@"Error: lang or title zero length.");
                continue;
            }

            // Get existing article record. Create article record if not found.
            Article *article = nil;
            NSManagedObjectID *existingArticleID = [context getArticleIDForTitle:title domain:lang];
            if (existingArticleID) {
                article = (Article *)[context objectWithID:existingArticleID];
            }else{
                article =
                [NSEntityDescription insertNewObjectForEntityForName: @"Article"
                                              inManagedObjectContext: context];
            }

            if (!article) {
                NSLog(@"Error: could not create or find article.");
                continue;
            }

            // Is there aready a saved record associated with this article?
            Saved *alreadySaved =
                (Saved *)[context getEntityForName: @"Saved"
                               withPredicateFormat: @"article == %@", article];

            if (alreadySaved) {
                NSLog(@"Warning: article already saved.");
                continue;
            }

            // All needed data in place and no saved record already exists, so safe to proceed.
            article.dateCreated = [NSDate date];
            article.site = @"wikipedia.org";
            article.domain = lang;
            article.title = title;
            article.needsRefresh = @YES;
            article.lastmodifiedby = @"";
            article.redirected = @"";
            article.domainName =
                [WikipediaAppUtils domainNameForCode:article.domain];

            // Add saved record for article.
            Saved *saved =
                [NSEntityDescription insertNewObjectForEntityForName: @"Saved"
                                              inManagedObjectContext: context];

            saved.dateSaved = [NSDate date];

            [article addSavedObject:saved];

            [funnel logImportOnSubdomain:lang];
        }

        // Save all the additions from the loop above in one go.
        if (![context save:&error]) {
            NSLog(@"Error saving to context = %@", error);
        }

       }];
     */
}

@end
