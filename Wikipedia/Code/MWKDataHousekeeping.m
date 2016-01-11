//  Created by Monte Hurd on 6/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKDataHousekeeping.h"
#import "NSDate+Utilities.h"
#import "SessionSingleton.h"
#import "Wikipedia-Swift.h"
#import "MediaWikiKit.h"

#import <BlocksKit/BlocksKit.h>

#define MAX_HISTORY_ENTRIES 100

@interface MWKDataHousekeeping (){
}

@end

@implementation MWKDataHousekeeping

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)performHouseKeeping {
    SessionSingleton* session       = [SessionSingleton sharedInstance];
    MWKDataStore* dataStore         = session.dataStore;
    MWKUserDataStore* userDataStore = session.userDataStore;
    MWKHistoryList* historyList     = userDataStore.historyList;
    MWKSavedPageList* savedPageList = userDataStore.savedPageList;


    NSMutableSet* articlesToSave = [NSMutableSet setWithCapacity:[savedPageList countOfEntries]];

    // Keep all saved pages
    for (MWKSavedPageEntry* entry in savedPageList) {
        [articlesToSave addObject:entry.title];
    }

    // Keep most recent MAX_HISTORY_ENTRIES history entries
    NSMutableArray* historyEntriesToPrune = [NSMutableArray arrayWithCapacity:[historyList countOfEntries]];
    int n                                 = 0;
    for (MWKHistoryEntry* entry in historyList) {
        if (n++ < MAX_HISTORY_ENTRIES) {
            // save!
            [articlesToSave addObject:entry.title];
        } else {
            // prune!
            [historyEntriesToPrune addObject:entry];
        }
    }

    [historyList removeEntriesFromHistory:historyEntriesToPrune];
    [historyList save].then(^(){
        // Iterate through all articles and de-cache the ones that aren't on the keep list
        // Cached metadata, section text, and images will be removed along with their articles.
        [dataStore iterateOverArticles:^(MWKArticle* article) {
            if (![articlesToSave containsObject:article.title]) {
                DDLogInfo(@"Pruning unsaved article %@", article.title);
                [article remove];
            }
        }];
    });
}

@end
