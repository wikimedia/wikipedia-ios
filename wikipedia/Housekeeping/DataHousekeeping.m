//  Created by Monte Hurd on 6/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DataHousekeeping.h"
#import "NSDate-Utilities.h"

#import "SessionSingleton.h"

#define MAX_HISTORY_ENTRIES 100

@interface DataHousekeeping (){
}

@end

@implementation DataHousekeeping

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void)performHouseKeeping
{
    
    SessionSingleton *session = [SessionSingleton sharedInstance];
    MWKDataStore *dataStore = session.dataStore;
    MWKUserDataStore *userDataStore = session.userDataStore;
    MWKHistoryList *historyList = userDataStore.historyList;
    MWKSavedPageList *savedPageList = userDataStore.savedPageList;
    
    
    NSMutableDictionary *articlesToSave = [@{} mutableCopy];

    // Keep all saved pages
    for (MWKSavedPageEntry *entry in savedPageList) {
        articlesToSave[entry.title] = entry.title;
    }
    
    // Keep most recent MAX_HISTORY_ENTRIES history entries
    NSMutableArray *historyEntriesToPrune = [@[] mutableCopy];
    int n = 0;
    for (MWKHistoryEntry *entry in historyList) {
        if (n++ < MAX_HISTORY_ENTRIES) {
            // save!
            articlesToSave[entry.title] = entry.title;
        } else {
            // prune!
            [historyEntriesToPrune addObject:entry];
        }
    }
    for (MWKHistoryEntry *entry in historyEntriesToPrune) {
        [historyList removeEntry:entry];
    }
    [userDataStore save];
    
    // Iterate through all articles and de-cache the ones that aren't on the keep list
    // Cached metadata, section text, and images will be removed along with their articles.
    [dataStore iterateOverArticles:^(MWKArticle *article) {
        if (articlesToSave[article.title]) {
            // don't kill it!
        } else {
            NSLog(@"Pruning unsaved article %@ %@", article.title.site.language, article.title.prefixedText);
            [article remove];
        }
    }];
}
@end
