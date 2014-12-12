//
//  MWKDataStoreTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticleStoreTestCase.h"

@implementation MWKArticleStoreTestCase

- (void)setUp {
    [super setUp];
    self.site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    self.title = [self.site titleWithString:@"San Francisco"];
    
    self.json0 = [self loadJSON:@"section0"];
    self.json1 = [self loadJSON:@"section1-end"];
    self.jsonAnon = [self loadJSON:@"organization-anon"];
    
    NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.basePath = [documentsFolder stringByAppendingPathComponent:@"unit-test-data"];
    
    self.dataStore = [[MWKDataStore alloc] initWithBasePath:self.basePath];
    self.article = [self.dataStore articleWithTitle:self.title];
}

- (void)tearDown {
    [super tearDown];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.basePath error:nil];
}

@end
