//
//  MWKSiteTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKSiteTests : MWKTestCase

@end

@implementation MWKSiteTests {
    MWKSite *site;
}

- (void)setUp {
    [super setUp];
    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDomain
{
    XCTAssertEqualObjects(site.domain, @"wikipedia.org");
}

- (void)testLanguage
{
    XCTAssertEqualObjects(site.language, @"en");
}

- (void)testEquals
{
    MWKSite *otherSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(site, otherSite);

    otherSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];
    XCTAssertNotEqualObjects(site, otherSite);
    
    otherSite = [[MWKSite alloc] initWithDomain:@"wiktionary.org" language:@"en"];
    XCTAssertNotEqualObjects(site, otherSite);
}

- (void)testStrings
{
    XCTAssertEqualObjects([site titleWithString:@"India"].prefixedText, @"India");
    XCTAssertEqualObjects([site titleWithString:@"Talk:India"].prefixedText, @"Talk:India");
    XCTAssertEqualObjects([site titleWithString:@"Talk:India#History"].prefixedText, @"Talk:India");
}

- (void)testLinks
{
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/India"].prefixedText, @"India");
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/Talk:India"].prefixedText, @"Talk:India");
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/Talk:India#History"].prefixedText, @"Talk:India");
    //    XCTAssertThrows([site titleWithInternalLink:@"/upload/foobar"]);
}

@end
