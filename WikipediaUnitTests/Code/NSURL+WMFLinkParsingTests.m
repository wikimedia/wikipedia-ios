#import <XCTest/XCTest.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSURLComponents+WMFLinkParsing.h>

@interface NSURL_WMFLinkParsingTests : XCTestCase

@end

@implementation NSURL_WMFLinkParsingTests

- (void)testCitationURL {
    XCTAssertTrue(([[NSURL URLWithString:@"#cite_note-0"] wmf_isWikiCitation]));
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
    NSURL *testURL = [[NSURL URLWithString:@"/wiki/"]
        URLByAppendingPathComponent:testPath];
    XCTAssert([[testURL wmf_pathWithoutWikiPrefix] isEqualToString:testPath]);
}

- (void)testInternalLinkPathForURLExcludesFragmentAndQuery {
    NSString *testPath = @"foo/bar";
    NSString *testPathWithQueryAndFragment = [@"/wiki/" stringByAppendingFormat:@"%@?baz#buz", testPath];
    XCTAssert([[[NSURL URLWithString:testPathWithQueryAndFragment] wmf_pathWithoutWikiPrefix] isEqualToString:testPath]);
}

- (void)testTalkPageDatabaseKeyEN {
    NSString *urlString = @"https://en.wikipedia.org/api/rest_v1/page/talk/Username";
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSString *talkPageDatabaseKey = [url wmf_databaseKey];
    XCTAssertTrue([talkPageDatabaseKey isEqualToString:urlString]);
    //todo: flesh this out. how do we handle sub paths after username/, query items after that, underscores for spaces, url percent encoding, etc.
}

- (void)testTalkPageDatabaseKeyES {
    NSString *urlString = @"https://es.wikipedia.org/api/rest_v1/page/talk/Username";
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSString *talkPageDatabaseKey = [url wmf_databaseKey];
    XCTAssertTrue([talkPageDatabaseKey isEqualToString:urlString]);
}

- (void)testLanguageVariantCodeProperty {
    NSURL *url = [[NSURL alloc] initWithString: @"https://zh.wikipedia.org"];
    XCTAssertNil(url.wmf_languageVariantCode);
    NSString *languageVariantCode = @"zh-hant";
    url.wmf_languageVariantCode = languageVariantCode;
    XCTAssertEqualObjects(url.wmf_languageVariantCode, languageVariantCode);
}

- (void)testLanguageVariantCodePropertyFromURLComponents {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://sr.wikipedia.org"];
    NSString *languageVariantCode = @"sr-ec";
    XCTAssertNotNil(components);
    NSURL *url = [components wmf_URLWithLanguageVariantCode:languageVariantCode];
    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.wmf_languageVariantCode, languageVariantCode);
}

@end
