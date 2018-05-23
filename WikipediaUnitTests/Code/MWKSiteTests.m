#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKSiteTests : MWKTestCase

@end

@implementation MWKSiteTests {
    NSURL *siteURL;
}

- (void)setUp {
    [super setUp];
    siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDomain {
    XCTAssertEqualObjects(siteURL.wmf_domain, @"wikipedia.org");
}

- (void)testLanguage {
    XCTAssertEqualObjects(siteURL.wmf_language, @"en");
}

- (void)testEquals {
    NSURL *otherSiteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    XCTAssertEqualObjects(siteURL, otherSiteURL);

    otherSiteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];
    XCTAssertNotEqualObjects(siteURL, otherSiteURL);

    otherSiteURL = [NSURL wmf_URLWithDomain:@"wiktionary.org" language:@"en"];
    XCTAssertNotEqualObjects(siteURL, otherSiteURL);
}

- (void)testStrings {
    XCTAssertEqualObjects([siteURL wmf_URLWithTitle:@"India"].wmf_title, @"India");
    XCTAssertEqualObjects([siteURL wmf_URLWithTitle:@"Talk:India"].wmf_title, @"Talk:India");
    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"Talk:India#History"].wmf_title, @"Talk:India");
}

- (void)testStringsWithQuery {
    XCTAssertEqualObjects([siteURL wmf_URLWithTitle:@"India"].wmf_title, @"India");
    XCTAssertEqualObjects([siteURL wmf_URLWithTitle:@"Talk:India"].wmf_title, @"Talk:India");
    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"Talk:India?wprov=stii1&a=%3Fb&c=%3F%3F#History"].wmf_title, @"Talk:India");
}

- (void)testLinks {
    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/India"].wmf_title, @"India");
    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/Talk:India"].wmf_title, @"Talk:India");

    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/Talk:India#History"].wmf_title, @"Talk:India");
    XCTAssertEqualObjects([NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/2008 ACC Men%27s Basketball Tournament"].wmf_title, @"2008 ACC Men's Basketball Tournament");
}

@end
