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
    MWKSite* site;
}

- (void)setUp {
    [super setUp];
    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDomain {
    XCTAssertEqualObjects(site.domain, @"wikipedia.org");
}

- (void)testLanguage {
    XCTAssertEqualObjects(site.language, @"en");
}

- (void)testEquals {
    MWKSite* otherSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(site, otherSite);

    otherSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];
    XCTAssertNotEqualObjects(site, otherSite);

    otherSite = [[MWKSite alloc] initWithDomain:@"wiktionary.org" language:@"en"];
    XCTAssertNotEqualObjects(site, otherSite);
}

- (void)testStrings {
    XCTAssertEqualObjects([site titleWithString:@"India"].text, @"India");
    XCTAssertEqualObjects([site titleWithString:@"Talk:India"].text, @"Talk:India");
    XCTAssertEqualObjects([site titleWithString:@"Talk:India#History"].text, @"Talk:India");
}

- (void)testLinks {
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/India"].text, @"India");
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/Talk:India"].text, @"Talk:India");
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/Talk:India#History"].text, @"Talk:India");
    XCTAssertEqualObjects([site titleWithInternalLink:@"/wiki/2008 ACC Men%27s Basketball Tournament"].text,
                          @"2008 ACC Men's Basketball Tournament");
    //    XCTAssertThrows([site titleWithInternalLink:@"/upload/foobar"]);
}

@end
