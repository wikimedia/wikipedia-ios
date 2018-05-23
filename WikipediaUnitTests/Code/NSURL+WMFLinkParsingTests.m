#import <XCTest/XCTest.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import "NSString+WMFPageUtilities.h"

@interface NSURL_WMFLinkParsingTests : XCTestCase

@end

@implementation NSURL_WMFLinkParsingTests

- (void)testCitationURL {
    XCTAssertTrue(([[NSURL URLWithString:[NSString stringWithFormat:@"#%@-0", WMFCitationFragmentSubstring]] wmf_isWikiCitation]));
}

- (void)testURLWithoutFragmentIsNotCitation {
    XCTAssertFalse([[NSURL URLWithString:@"/wiki/Foo"] wmf_isWikiCitation]);
}

- (void)testURLWithFragmentNotContainingCitaitonSubstringIsNotCitation {
    XCTAssertFalse([[NSURL URLWithString:@"/wiki/Foo#bar"] wmf_isWikiCitation]);
}

- (void)testRelativeInternalLink {
    XCTAssertTrue([[NSURL URLWithString:@"/wiki/Foo"] wmf_isWikiResource]);
}

- (void)testAbsoluteInternalLink {
    XCTAssertTrue([[NSURL URLWithString:@"https://en.wikipedia.org/wiki/Foo"] wmf_isWikiResource]);
}

- (void)testAbsoluteInternalLinkWithOtherComponents {
    XCTAssertTrue([[NSURL URLWithString:@"https://en.wikipedia.org/wiki/Foo?query=&string=value#fragment"] wmf_isWikiResource]);
}

- (void)testRelativeExternalLink {
    XCTAssertFalse([[NSURL URLWithString:@"/Foo"] wmf_isWikiResource]);
}

- (void)testAbsoluteExternalLink {
    XCTAssertFalse([[NSURL URLWithString:@"https://www.foo.com/bar"] wmf_isWikiResource]);
}

- (void)testInternalLinkPath {
    NSString *testPath = @"foo/bar";
    NSURL *testURL = [[NSURL URLWithString:WMFInternalLinkPathPrefix]
        URLByAppendingPathComponent:testPath];
    XCTAssert([[testURL wmf_pathWithoutWikiPrefix] isEqualToString:testPath]);
}

- (void)testInternalLinkPathForURLExcludesFragmentAndQuery {
    NSString *testPath = @"foo/bar";
    NSString *testPathWithQueryAndFragment = [WMFInternalLinkPathPrefix stringByAppendingFormat:@"%@?baz#buz", testPath];
    XCTAssert([[[NSURL URLWithString:testPathWithQueryAndFragment] wmf_pathWithoutWikiPrefix] isEqualToString:testPath]);
}


@end
