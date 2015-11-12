//
//  WMFSearchFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"

#import "LSStubResponseDSL+WithJSON.h"
#import "XCTestCase+PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSearchFetcherTests : XCTestCase
@property (nonatomic, strong) WMFSearchFetcher* fetcher;
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

- (void)testSerializesAndStopsAtAdequatePrefixSearchResults {
    id json = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"BarackSearch"];

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
    .andReturn(200)
    .withJSON(json);

    expectResolution(^{
        return [self.fetcher fetchArticlesForSearchTerm:@"foo" site:[MWKSite random] resultLimit:15]
        .then(^(WMFSearchResults* result) {
            assertThat(result.results, hasCountOf([[json valueForKeyPath:@"query.pages"] count]));
        });
    });
}

- (void)testAppendingToPreviousResultsCausesKVOEvents {
    id prefixSearchJSON   = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MonetPrefixSearch"];
    id fullTextSearchJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MonetFullTextSearch"];

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=prefixsearch.*foo.*" options:0 error:nil])
    .andReturn(200)
    .withJSON(prefixSearchJSON);

    stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"generator=search.*foo.*" options:0 error:nil])
    .andReturn(200)
    .withJSON(fullTextSearchJSON);

    NSArray<NSString*>* prefixTitles =
        [[[prefixSearchJSON valueForKeyPath:@"query.pages"] allValues] valueForKey:@"title"];

    NSArray<NSString*>* fullTextTitles =
        [[[fullTextSearchJSON valueForKeyPath:@"query.pages"] allValues] valueForKey:@"title"];

    NSMutableSet* uniqueTitles = [NSMutableSet setWithArray:prefixTitles];
    [uniqueTitles addObjectsFromArray:fullTextTitles];

    MWKSite* searchSite = [MWKSite random];

    __block WMFSearchResults* prefixResults;

    // get prefix result
    expectResolution(^{
        return [self.fetcher fetchArticlesForSearchTerm:@"foo" site:searchSite resultLimit:15]
        .then(^(WMFSearchResults* prefixResult) {
            assertThat(prefixResults.results, hasCountOf(prefixTitles.count));
            prefixResults = prefixResult;
        });
    });

    // expect KVO notification
    [self keyValueObservingExpectationForObject:prefixResults
                                        keyPath:WMF_SAFE_KEYPATH(prefixResults, results)
                                  expectedValue:nil];

    // fetch full-text results, appending to prefix
    expectResolution(^{
        return [self.fetcher fetchArticlesForSearchTerm:@"foo"
                                                   site:searchSite
                                            resultLimit:15
                                         fullTextSearch:YES
                                appendToPreviousResults:prefixResults]
        .then(^(WMFSearchResults* appendedResults) {
            assertThat(appendedResults.results, hasCountOf(uniqueTitles.count));
        });
    });
}

@end
