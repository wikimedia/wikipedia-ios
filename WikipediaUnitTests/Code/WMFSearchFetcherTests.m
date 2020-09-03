#import <XCTest/XCTest.h>
#import "WMFSearchFetcher_Testing.h"
#import "WMFSearchResults_Internal.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"
#import "LSStubResponseDSL+WithJSON.h"
#import "XCTestCase+WMFBundleConvenience.h"
#import "NSBundle+TestAssets.h"

@interface WMFSearchFetcherTests : XCTestCase
@property (nonatomic, strong) WMFSearchFetcher *fetcher;
@end

@implementation WMFSearchFetcherTests

- (void)setUp {
    [super setUp];
    self.fetcher = [[WMFSearchFetcher alloc] init];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)testNonEmptyPrefixResponse {
    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"BarackSearch"];
    NSParameterAssert(json);

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
        .andReturn(200)
        .withJSON(json);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for articles"];

    [self.fetcher fetchArticlesForSearchTerm:@"foo"
        siteURL:[NSURL URLWithString:@"https://en.wikipedia.org"]
        resultLimit:15
        failure:^(NSError *error) {
            XCTFail(@"Error");
            [expectation fulfill];
        }
        success:^(WMFSearchResults *result) {
            XCTAssertEqual(result.results.count, [[json valueForKeyPath:@"query.pages"] count]);
            [expectation fulfill];
        }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     XCTFail(@"Timeout");
                                 }];
}

- (void)testEmptyPrefixResponse {
    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
    NSParameterAssert(json);

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
        .andReturn(200)
        .withJSON(json);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for articles"];

    [self.fetcher fetchArticlesForSearchTerm:@"foo"
        siteURL:[NSURL URLWithString:@"https://en.wikipedia.org"]
        resultLimit:15
        failure:^(NSError *error) {
            XCTFail(@"Error");
            [expectation fulfill];
        }
        success:^(WMFSearchResults *result) {
            XCTAssertEqual(result.searchSuggestion, [json valueForKeyPath:@"query.searchinfo.suggestion"]);
            XCTAssert(result.results.count == 0);
            [expectation fulfill];
        }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     XCTFail(@"Timeout");
                                 }];
}

@end
