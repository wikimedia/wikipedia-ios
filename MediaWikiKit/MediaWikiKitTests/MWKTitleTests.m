//
//  MWKTitleTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#include "MWKTestCase.h"

@interface MWKTitleTests : MWKTestCase

@end

@implementation MWKTitleTests {
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

- (void)testSimple {
    MWKTitle *title = [MWKTitle titleWithString:@"Simple" site:site];

    XCTAssertNil(title.namespace, @"Namespace is nil");
    XCTAssertEqualObjects(title.prefixedDBKey, @"Simple", @"DB key form is full");
    XCTAssertEqualObjects(title.prefixedText, @"Simple", @"Text form is full");
    XCTAssertEqualObjects(title.prefixedURL, @"Simple", @"URL form is full");
    XCTAssertNil(title.fragment, @"Fragment is nil");
    XCTAssertEqualObjects(title.fragmentForURL, @"", @"Fragment for URL is empty string");
}

- (void)testFancy {
    NSArray *inputs = @[[MWKTitle titleWithString:@"Fancy title with spaces" site:site],
                        [MWKTitle titleWithString:@"Fancy_title with_spaces" site:site]
                        ];
    for (MWKTitle *title in inputs) {
        XCTAssertNil(title.namespace, @"Namespace is nil");
        XCTAssertEqualObjects(title.prefixedDBKey, @"Fancy_title_with_spaces", @"DB key form has underscores");
        XCTAssertEqualObjects(title.prefixedText, @"Fancy title with spaces", @"Text form has spaces");
        XCTAssertEqualObjects(title.prefixedURL, @"Fancy_title_with_spaces", @"URL form has underscores");
        XCTAssertNil(title.fragment, @"Fragment is nil");
        XCTAssertEqualObjects(title.fragmentForURL, @"", @"Fragment for URL is empty string");
    }
}

- (void)testUnicode {
    MWKTitle *title = [MWKTitle titleWithString:@"Éclair" site:site];
    XCTAssertNil(title.namespace, @"Namespace is nil");
    XCTAssertEqualObjects(title.prefixedDBKey, @"Éclair", @"DB key form has unicode");
    XCTAssertEqualObjects(title.prefixedText, @"Éclair", @"Text form has unicode");
    XCTAssertEqualObjects(title.prefixedURL, @"%C3%89clair", @"URL form has percent encoding");
    XCTAssertNil(title.fragment, @"Fragment is nil");
    XCTAssertEqualObjects(title.fragmentForURL, @"", @"Fragment for URL is empty string");
}

- (void)testEquals {
    MWKTitle *title = [site titleWithString:@"Foobie foo"];
    MWKTitle *title2 = [site titleWithString:@"Foobie foo"];
    XCTAssertEqualObjects(title, title2);
    
    MWKTitle *title3 = [site titleWithString:@"Foobie_foo"];
    XCTAssertEqualObjects(title, title3);

    MWKTitle *title4 = [site titleWithString:@"Foobie_Foo"];
    XCTAssertNotEqualObjects(title, title4);
    
    MWKSite *site2 = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];
    MWKTitle *title5 = [site2 titleWithString:@"Foobie foo"];
    XCTAssertNotEqualObjects(title, title5);
}

@end
