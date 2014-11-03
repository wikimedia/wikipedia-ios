//
//  MWKArticleFetcherTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKArticleTests : MWKTestCase

@end

@implementation MWKArticleTests {
    MWKSite *site;
    MWKTitle *title;
    NSDictionary *json;
    MWKArticle *article;
}

- (void)setUp {
    [super setUp];

    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    title = [site titleWithString:@"San Francisco"];
    
    json = [self loadJSON:@"section0"];
    
    article = [[MWKArticle alloc] initWithTitle:title dict:json[@"mobileview"]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testFromJSON {
    XCTAssertNotNil(json, @"Loaded JSON");
    XCTAssertNotNil(article, @"Got an article");
}

- (void)testRequiredFieldsPresent {
    XCTAssertNotNil(article.lastmodified, @"lastmodified is required");
    XCTAssertNotNil(article.lastmodifiedby, @"lastmodifiedby is required");
}

- (void)testOptionalFieldsPresent {
    XCTAssertNil(article.redirected, @"redirected is empty");
    XCTAssertEqualObjects(article.displaytitle, @"San Francisco", @"displaytitle is present");
}

- (void)testRoundTrip {
    NSDictionary *export = [article dataExport];
    XCTAssertNotNil(export, @"Got a data export");
    MWKArticle *article2 = [[MWKArticle alloc] initWithTitle:title dict:export];
    XCTAssertNotNil(article2, @"Got an article round-tripped");
    XCTAssertEqualObjects(article, article2, @"round-trip is same");
}


@end
