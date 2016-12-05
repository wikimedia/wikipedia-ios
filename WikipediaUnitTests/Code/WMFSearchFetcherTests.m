#import <XCTest/XCTest.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "WMFSearchFetcher_Testing.h"
#import "WMFSearchResults_Internal.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"

#import "LSStubResponseDSL+WithJSON.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

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
    
    
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        
    }];
    expectResolutionWithTimeout(10, ^{
        return [self.fetcher fetchArticlesForSearchTerm:@"foo" siteURL:[NSURL wmf_randomSiteURL] resultLimit:15]
            .then(^(WMFSearchResults *result) {
                assertThat(result.results, hasCountOf([[json valueForKeyPath:@"query.pages"] count]));
            });
    });
}

- (void)testEmptyPrefixResponse {
    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
    NSParameterAssert(json);

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
        .andReturn(200)
        .withJSON(json);

    expectResolutionWithTimeout(10, ^{
        return [self.fetcher fetchArticlesForSearchTerm:@"foo" siteURL:[NSURL wmf_randomSiteURL] resultLimit:15]
            .then(^(WMFSearchResults *result) {
                assertThat(result.searchSuggestion, is([json valueForKeyPath:@"query.searchinfo.suggestion"]));
                assertThat(result.results, isEmpty());
            });
    });
}

- (void)testAppendingToPrefixResults {
    NSData *prefixResponseData =
        [[self wmf_bundle] wmf_dataFromContentsOfFile:@"NoSearchResultsWithSuggestion"
                                               ofType:@"json"];
    NSParameterAssert(prefixResponseData);

    WMFSearchResults *prefixResults =
        [self.fetcher.operationManager.responseSerializer responseObjectForResponse:nil
                                                                               data:prefixResponseData
                                                                              error:nil];
    prefixResults.searchTerm = @"foo";

    XCTAssertNotNil(prefixResults, @"Failed to serialize prefix response fixture.");

    NSData *fullTextSearchJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MonetFullTextSearch" ofType:@"json"];
    NSParameterAssert(fullTextSearchJSONData);

    WMFSearchResults *fullTextResults =
        [self.fetcher.operationManager.responseSerializer responseObjectForResponse:nil
                                                                               data:fullTextSearchJSONData
                                                                              error:nil];
    fullTextResults.searchTerm = prefixResults.searchTerm;

    XCTAssertNotNil(fullTextResults, @"Failed to serialize full-text response fixture");

    WMFSearchResults *expectedMergedResults =
        [self.fetcher.operationManager.responseSerializer responseObjectForResponse:nil
                                                                               data:prefixResponseData
                                                                              error:nil];
    // prefix results come before full-text
    [expectedMergedResults mergeValuesForKeysFromModel:fullTextResults];
    expectedMergedResults.searchTerm = prefixResults.searchTerm;

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*generator=search.*" options:0 error:nil])
        .andReturn(200)
        .withHeader(@"Content-Type", @"application/json")
        .withBody(fullTextSearchJSONData);

    // expect KVO notification, must be done outside of "expect" since you can't add expectations once waiting has started
    [self keyValueObservingExpectationForObject:prefixResults
                                        keyPath:WMF_SAFE_KEYPATH(prefixResults, results)
                                  expectedValue:nil];

    __block WMFSearchResults *appendedResults;

    expectResolutionWithTimeout(10, ^{
        return [self.fetcher fetchArticlesForSearchTerm:expectedMergedResults.searchTerm
                                                siteURL:[NSURL wmf_randomSiteURL]
                                            resultLimit:15
                                         fullTextSearch:YES
                                appendToPreviousResults:prefixResults]
            .then(^(WMFSearchResults *fullTextResults) {
                appendedResults = fullTextResults;
            });
    });

    XCTAssertEqual(prefixResults, appendedResults, @"Expected full text results to be appended to prefix results object.");
    assertThat(appendedResults, is(equalTo(expectedMergedResults)));
}

@end
