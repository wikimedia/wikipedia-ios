//
//  SchemaConverter.m
//  Wikipedia
//
//  Created by Brion on 12/29/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "SchemaConverter.h"

@implementation SchemaConverter

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.dataStore     = dataStore;
        self.userDataStore = [self.dataStore userDataStore];
    }
    return self;
}

- (MWKArticle*)oldDataSchema:(OldDataSchemaMigrator*)schema migrateArticle:(NSDictionary*)articleDict {
    NSString* language       = articleDict[@"language"];
    NSString* titleStr       = articleDict[@"title"];
    NSDictionary* mobileview = articleDict[@"dict"];

    MWKSite* site       = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:language];
    MWKTitle* title     = [site titleWithString:titleStr];
    MWKArticle* article = [self.dataStore articleWithTitle:title];
    [article importMobileViewJSON:mobileview];
    @try {
        [article save];
    } @catch (NSException* ex) {
        NSLog(@"IMPORT ERROR on article %@. %@", article, ex);
    }
    return article;
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema
         migrateImage:(NSDictionary*)imageDict
           newArticle:(MWKArticle*)newArticle {
    NSString* language  = imageDict[@"language"];
    NSString* titleStr  = imageDict[@"title"];
    NSString* sourceURL = imageDict[@"sourceURL"];

    // TODO: add width & height?
    NSNumber* sectionId = imageDict[@"sectionId"];
    int sectionIdValue  = sectionId ? sectionId.intValue : kMWKArticleSectionNone;
    NSData* imageData   = imageDict[@"data"];
    @try {
        // import URL & update image lists
        MWKImage* image = [newArticle importImageURL:sourceURL sectionId:sectionIdValue];
        // import image data & save
        [image importImageData:imageData];
    } @catch (NSException* ex) {
        NSLog(@"IMPORT ERROR on image %@ in article %@:%@: %@", sourceURL, language, titleStr, ex);
    }
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateHistoryEntry:(NSDictionary*)historyDict {
    NSString* language        = historyDict[@"language"];
    NSString* titleStr        = historyDict[@"title"];
    NSString* date            = historyDict[@"date"];
    NSString* discoveryMethod = historyDict[@"discoveryMethod"];

    NSMutableDictionary* dict = [@{} mutableCopy];
    dict[@"domain"]          = @"wikipedia.org";
    dict[@"language"]        = language;
    dict[@"title"]           = titleStr;
    dict[@"date"]            = date;
    dict[@"discoveryMethod"] = discoveryMethod;
    dict[@"scrollPosition"]  = @(0); // @fixme extract from article?

    @try {
        MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithDict:dict];

        MWKHistoryList* historyList = self.userDataStore.historyList;
        [historyList addEntry:entry];
        [self.userDataStore save];
    }@catch (NSException* ex) {
        NSLog(@"IMPORT ERROR on history entry %@:%@: %@", language, titleStr, ex);
    }
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateSavedEntry:(NSDictionary*)savedDict {
    NSString* language = savedDict[@"language"];
    NSString* titleStr = savedDict[@"title"];

    NSMutableDictionary* dict = [@{} mutableCopy];
    dict[@"domain"]   = @"wikipedia.org";
    dict[@"language"] = language;
    dict[@"title"]    = titleStr;

    @try {
        MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithDict:dict];

        MWKSavedPageList* savedPageList = self.userDataStore.savedPageList;
        [savedPageList addEntry:entry];
        [self.userDataStore save];
    }@catch (NSException* ex) {
        NSLog(@"IMPORT ERROR on saved entry %@:%@: %@", language, titleStr, ex);
    }
}

@end
