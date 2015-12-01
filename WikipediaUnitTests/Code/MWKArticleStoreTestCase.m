//
//  MWKDataStoreTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticleStoreTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@implementation MWKArticleStoreTestCase

- (void)setUp {
    [super setUp];
    self.site  = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    self.title = [self.site titleWithString:@"San Francisco"];

    self.json0    = [self loadJSON:@"section0"];
    self.json1    = [self loadJSON:@"section1-end"];
    self.jsonAnon = [self loadJSON:@"organization-anon"];

    self.dataStore = [MWKDataStore temporaryDataStore];
    self.article   = [self.dataStore articleWithTitle:self.title];
}

- (void)tearDown {
    [self.dataStore removeFolderAtBasePath];
    [super tearDown];
}

@end
