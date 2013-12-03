//
//  SiteTests.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WikipediaApp.h"

@interface SiteTests : XCTestCase

@end

@implementation SiteTests {
    MWSite *site;
}

- (void)setUp
{
    [super setUp];
    site = [[MWSite alloc] initWithDomain:@"en.wikipedia.org"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testDomain
{
    XCTAssertEqualObjects(site.domain, @"en.wikipedia.org");
}

- (void)testEquals
{
    MWSite *otherSite = [[MWSite alloc] initWithDomain:@"en.wikipedia.org"];
    XCTAssertEqualObjects(site, otherSite);
}

- (void)testLinks
{
    XCTAssertEqualObjects([site titleForInternalLink:@"/wiki/India"].prefixedText, @"India");
    XCTAssertEqualObjects([site titleForInternalLink:@"/wiki/Talk:India"].prefixedText, @"Talk:India");
    XCTAssertEqualObjects([site titleForInternalLink:@"/wiki/Talk:India#History"].prefixedText, @"Talk:India");
//    XCTAssertThrows([site titleForInternalLink:@"/upload/foobar"]);
}

@end
