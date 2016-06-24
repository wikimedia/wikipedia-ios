//
//  MWKTitleTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKTitleTests : MWKTestCase

@end

@implementation MWKTitleTests {
    MWKSite* site;
}

- (void)setUp {
    [super setUp];
    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testNilResultsInEmptyString {
    MWKTitle* title;
    XCTAssertNoThrow((title = [site titleWithString:nil]));
    assertThat(title.text, is(@""));
}

- (void)testPermitsEmptyString {
    MWKTitle* title;
    XCTAssertNoThrow((title = [site titleWithString:@""]));
    assertThat(title.text, is(@""));
}

#pragma clang diagnostic pop

- (void)testSimple {
    MWKTitle* title = [MWKTitle titleWithString:@"Simple" site:site];
    XCTAssertEqualObjects(title.text, @"Simple", @"Text form is full");
    XCTAssertNil(title.fragment, @"Fragment is nil");
}

- (void)testUnderscoresAndSpaces {
    NSArray* inputs = @[[MWKTitle titleWithString:@"Fancy title with spaces" site:site],
                        [MWKTitle titleWithString:@"Fancy_title with_spaces" site:site]];
    for (MWKTitle* title in inputs) {
        XCTAssertEqualObjects(title.text, @"Fancy title with spaces", @"Text form has spaces");
        XCTAssertNil(title.fragment, @"Fragment is nil");
    }
}

- (void)testUnicode {
    MWKTitle* title = [MWKTitle titleWithString:@"Éclair" site:site];
    XCTAssertEqualObjects(title.text, @"Éclair", @"Text form has unicode");
    XCTAssertNil(title.fragment, @"Fragment is nil");
}

- (void)testFragment {
    MWKTitle* title = [MWKTitle titleWithString:@"foo#bar" site:site];
    assertThat(title.site, is(site));
    assertThat(title.text, is(@"foo"));
    assertThat(title.fragment, is(@"bar"));
}

- (void)testPercentEscaped {
    MWKTitle* title = [MWKTitle titleWithString:@"foo%20baz#bar" site:site];
    assertThat(title.site, is(site));
    assertThat(title.text, is(@"foo baz"));
    assertThat(title.fragment, is(@"bar"));
}

- (void)testEquals {
    MWKTitle* title  = [site titleWithString:@"Foobie foo"];
    MWKTitle* title2 = [site titleWithString:@"Foobie foo"];
    XCTAssertEqualObjects(title, title2);

    MWKTitle* title3 = [site titleWithString:@"Foobie_foo"];
    XCTAssertEqualObjects(title, title3);

    MWKTitle* title4 = [site titleWithString:@"Foobie_Foo"];
    XCTAssertNotEqualObjects(title, title4);

    MWKSite* site2   = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"fr"];
    MWKTitle* title5 = [site2 titleWithString:@"Foobie foo"];
    XCTAssertNotEqualObjects(title, title5);
}

@end
