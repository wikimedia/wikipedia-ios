////
////  WMFSearchFetcherTests.m
////  Wikipedia
////
////  Created by Brian Gerstle on 11/11/15.
////  Copyright © 2015 Wikimedia Foundation. All rights reserved.
////
//
//#import <XCTest/XCTest.h>
//#import "WMFSearchFetcher.h"
//#import "WMFSearchResults.h"
//
//#import "LSStubResponseDSL+WithJSON.h"
//#import "XCTestCase+PromiseKit.h"
//
//#define HC_SHORTHAND 1
//#import <OCHamcrest/OCHamcrest.h>
//
//@interface WMFSearchFetcherTests : XCTestCase
//@property (nonatomic, strong) WMFSearchFetcher* fetcher;
//@end
//
//@implementation WMFSearchFetcherTests
//
//- (void)setUp {
//    [super setUp];
//    self.fetcher = [[WMFSearchFetcher alloc] init];
//    [[LSNocilla sharedInstance] start];
//}
//
//- (void)tearDown {
//    [super tearDown];
//    [[LSNocilla sharedInstance] stop];
//}
//
//- (void)testSerializesAndStopsAtAdequatePrefixSearchResults {
//    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"BarackSearch"];
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(json);
//
//    expectResolutionWithTimeout(5, ^{
//        return [self.fetcher fetchArticlesForSearchTerm:@"foo" site:[MWKSite random] resultLimit:15]
//        .then(^(WMFSearchResults* result) {
//            assertThat(result.results, hasCountOf([[json valueForKeyPath:@"query.pages"] count]));
//        });
//    });
//}
//
//- (void)testHandlesSuggestionWithoutResults {
//    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(json);
//
//    expectResolutionWithTimeout(5, ^{
//        return [self.fetcher fetchArticlesForSearchTerm:@"foo" site:[MWKSite random] resultLimit:15]
//        .then(^(WMFSearchResults* result) {
//            assertThat(result.searchSuggestion, is([json valueForKeyPath:@"query.searchinfo.suggestion"]));
//            assertThat(result.results, isEmpty());
//        });
//    });
//}
//
//- (void)testAppendingToPreviousEmptyResultsCausesKVOEvents {
//    id noResultsJSON      = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
//    id fullTextSearchJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MonetFullTextSearch"];
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*generator=prefixsearch.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(noResultsJSON);
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*generator=search.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(fullTextSearchJSON);
//
//    NSArray<NSString*>* fullTextTitles =
//        [[[fullTextSearchJSON valueForKeyPath:@"query.pages"] allValues] valueForKey:@"title"];
//
//    WMFSearchResults* finalResults = [self verifyKVOEventWhenAppendingTitles:fullTextTitles toPrefixTitles:nil];
//    assertThat(finalResults.searchSuggestion, is([noResultsJSON valueForKeyPath:@"query.searchinfo.suggestion"]));
//}
//
//- (void)testAppendingToPreviousNonEmptyResultsCausesKVOEvents {
//    id prefixSearchJSON   = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MonetPrefixSearch"];
//    id fullTextSearchJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MonetFullTextSearch"];
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*generator=prefixsearch.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(prefixSearchJSON);
//
//    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*generator=search.*" options:0 error:nil])
//    .andReturn(200)
//    .withJSON(fullTextSearchJSON);
//
//    NSArray<NSString*>* prefixTitles =
//        [[[prefixSearchJSON valueForKeyPath:@"query.pages"] allValues] valueForKey:@"title"];
//
//    NSArray<NSString*>* fullTextTitles =
//        [[[fullTextSearchJSON valueForKeyPath:@"query.pages"] allValues] valueForKey:@"title"];
//
//    [self verifyKVOEventWhenAppendingTitles:fullTextTitles toPrefixTitles:prefixTitles];
//}
//
//#pragma mark - Utils
//
//- (WMFSearchResults*)verifyKVOEventWhenAppendingTitles:(NSArray*)fullTextTitles
//                                        toPrefixTitles:(nullable NSArray*)prefixTitles {
//    NSMutableSet* uniqueTitles = [NSMutableSet setWithArray:prefixTitles ? : @[]];
//    [uniqueTitles addObjectsFromArray:fullTextTitles];
//
//    MWKSite* searchSite = [MWKSite random];
//
//    __block WMFSearchResults* fetchedPrefixResult;
//
//    // get prefix result
//    expectResolutionWithTimeout(5, ^{
//        return [self.fetcher fetchArticlesForSearchTerm:@"foo" site:searchSite resultLimit:15]
//        .then(^(WMFSearchResults* prefixResult) {
//            assertThat(prefixResult.results, hasCountOf(prefixTitles.count));
//            fetchedPrefixResult = prefixResult;
//        });
//    });
//
//    // expect KVO notification
//    [self keyValueObservingExpectationForObject:fetchedPrefixResult
//                                        keyPath:WMF_SAFE_KEYPATH(fetchedPrefixResult, results)
//                                  expectedValue:nil];
//
//    // fetch full-text results, appending to prefix
//    expectResolutionWithTimeout(5, ^{
//        return [self.fetcher fetchArticlesForSearchTerm:@"foo"
//                                                   site:searchSite
//                                            resultLimit:15
//                                         fullTextSearch:YES
//                                appendToPreviousResults:fetchedPrefixResult]
//        .then(^(WMFSearchResults* appendedResults) {
//            XCTAssertEqual(fetchedPrefixResult, appendedResults, @"Expected resolved value to be identical to previous results object.");
//            assertThat(appendedResults.results, hasCountOf(uniqueTitles.count));
//        });
//    });
//    return fetchedPrefixResult;
//}
//
//@end
