//
//  MWKDataStoreTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKArticleStoreTestCase.h"

@interface MWKDataStoreStorageTests : MWKArticleStoreTestCase

@end

@implementation MWKDataStoreStorageTests

- (void)testWriteReadArticle
{
    XCTAssertThrows([self.dataStore articleWithTitle:self.title], @"article cannot be loaded before we save it");
    
    MWKArticle *article;
    article = [[MWKArticle alloc] initWithTitle:self.title dict:self.json0[@"mobileview"]];

    XCTAssertNoThrow([self.dataStore saveArticle:article]);
    
    MWKArticle *article2;
    XCTAssertNoThrow(article2 = [self.dataStore articleWithTitle:self.title], @"article can be loaded after saving it");
    
    XCTAssertEqualObjects(article, article2);
}

- (void)testArticleStoreSection0
{
    XCTAssertThrows([self.dataStore articleWithTitle:self.title], @"article cannot be loaded before we save it");
    
    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.json0]);
    
    MWKArticle *article;
    XCTAssertNoThrow(article = [self.dataStore articleWithTitle:self.title], @"article can be loaded after saving it");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForTitle:self.title] stringByAppendingPathComponent:@"Article.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 title:self.title] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 title:self.title] stringByAppendingPathComponent:@"Section.html"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 title:self.title] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertFalse([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 title:self.title] stringByAppendingPathComponent:@"Section.html"]]);
}

- (void)testArticleStoreSection1ToEnd
{
    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.json0]);
    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.json1]);
    
    MWKArticle *article;
    XCTAssertNoThrow(article = [self.dataStore articleWithTitle:self.title], @"article can be loaded after saving it");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForTitle:self.title] stringByAppendingPathComponent:@"Article.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 title:self.title] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 title:self.title] stringByAppendingPathComponent:@"Section.html"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 title:self.title] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 title:self.title] stringByAppendingPathComponent:@"Section.html"]]);
}

-(void)testArticleStoreReadSections
{
    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.json0]);
    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.json1]);

    NSArray *sections;
    XCTAssertNoThrow(sections = self.articleStore.sections);
    
    XCTAssertEqual([sections count], 36);
}

@end
