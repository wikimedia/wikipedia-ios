#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKTitleTests : MWKTestCase

@end

@implementation MWKTitleTests {
    NSURL *siteURL;
}

- (void)setUp {
    [super setUp];
    siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testNilResultsInNil {
    NSURL *title;
    XCTAssertNoThrow((title = [siteURL wmf_URLWithTitle:nil]));
    assertThat(title.wmf_title, is(nilValue()));
}

- (void)testPermitsEmptyString {
    NSURL *title;
    XCTAssertNoThrow((title = [siteURL wmf_URLWithTitle:@""]));
    assertThat(title.wmf_title, is(nilValue()));
}

#pragma clang diagnostic pop

- (void)testSimple {
    NSURL *title = [siteURL wmf_URLWithTitle:@"Simple"];
    XCTAssertEqualObjects(title.wmf_title, @"Simple", @"Text form is full");
    XCTAssertNil(title.fragment, @"Fragment is nil");
}

- (void)testUnderscoresAndSpaces {
    NSArray *inputs = @[[siteURL wmf_URLWithTitle:@"Fancy title with spaces"],
                        [siteURL wmf_URLWithTitle:@"Fancy_title with_spaces"]];
    for (NSURL *title in inputs) {
        XCTAssertEqualObjects(title.wmf_title, @"Fancy title with spaces", @"Text form has spaces");
        XCTAssertNil(title.fragment, @"Fragment is nil");
    }
}

- (void)testUnicode {
    NSURL *title = [siteURL wmf_URLWithTitle:@"Éclair"];
    XCTAssertEqualObjects(title.wmf_title, @"Éclair", @"Text form has unicode");
    XCTAssertNil(title.fragment, @"Fragment is nil");
}

- (void)testFragment {
    NSURL *title = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"foo#bar"];
    assertThat(title.wmf_siteURL, is(siteURL));
    assertThat(title.wmf_title, is(@"foo"));
    assertThat(title.fragment, is(@"bar"));
}

- (void)testPercentEscaped {
    NSURL *title = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"foo%20baz#bar"];
    assertThat(title.wmf_siteURL, is(siteURL));
    assertThat(title.wmf_title, is(@"foo baz"));
    assertThat(title.fragment, is(@"bar"));
}

- (void)testEquals {
    NSURL *title = [siteURL wmf_URLWithTitle:@"Foobie foo"];
    NSURL *title2 = [siteURL wmf_URLWithTitle:@"Foobie foo"];
    XCTAssertEqualObjects(title, title2);

    NSURL *title3 = [siteURL wmf_URLWithTitle:@"Foobie_foo"];
    XCTAssertEqualObjects(title, title3);

    NSURL *title4 = [siteURL wmf_URLWithTitle:@"Foobie_Foo"];
    XCTAssertNotEqualObjects(title, title4);

    NSURL *site2 = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"fr"];
    NSURL *title5 = [site2 wmf_URLWithTitle:@"Foobie foo"];
    XCTAssertNotEqualObjects(title, title5);
}

- (void)testCanonicalMappingEquality {
    NSURL *title = [siteURL wmf_URLWithTitle:@"Olé"];
    NSURL *title2 = [siteURL wmf_URLWithTitle:@"Ol\u00E9"];
    XCTAssertEqualObjects(title, title2);

    NSURL *title3 = [siteURL wmf_URLWithTitle:@"Ole\u0301"];
    XCTAssertEqualObjects(title, title3);

    title = [siteURL wmf_URLWithTitle:@"Olé#Olé"];
    title2 = [siteURL wmf_URLWithTitle:@"Ol\u00E9#Ol\u00E9"];
    XCTAssertEqualObjects(title, title2);

    title3 = [siteURL wmf_URLWithTitle:@"Ole\u0301#Ole\u0301"];
    XCTAssertEqualObjects(title, title3);
}

@end
