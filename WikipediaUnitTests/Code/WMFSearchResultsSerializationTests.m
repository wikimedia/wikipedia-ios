//
//  WMFSearchResultsSerializationTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/28/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import "WMFSearchResults+ResponseSerializer.h"
#import "MWKSearchResult.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFSearchResultsSerializationTests : XCTestCase

@end

@implementation WMFSearchResultsSerializationTests

- (void)testResultsAndRedirectsAreNonnullForZeroResultResponse {
    NSData *noResultJSONData =
        [[self wmf_bundle] wmf_dataFromContentsOfFile:@"NoSearchResultsWithSuggestion"
                                               ofType:@"json"];
    id noResultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
    NSError *error;
    WMFSearchResults *searchResults = [[WMFSearchResults responseSerializer] responseObjectForResponse:nil
                                                                                                  data:noResultJSONData
                                                                                                 error:&error];
    XCTAssertNil(error);
    assertThat(searchResults.results, isEmpty());
    assertThat(searchResults.redirectMappings, isEmpty());
    assertThat(searchResults.searchSuggestion, is([noResultJSON valueForKeyPath:@"query.searchinfo.suggestion"]));
}

- (void)testSerializesPrefixResultsInOrderOfIndex {
    NSString *fixtureName = @"BarackSearch";
    NSData *resultData = [[self wmf_bundle] wmf_dataFromContentsOfFile:fixtureName ofType:@"json"];

    NSDictionary *resultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"query"];

    NSArray<NSDictionary *> *resultJSONObjects = [resultJSON[@"pages"] allValues];

    NSError *error;
    WMFSearchResults *searchResults = [[WMFSearchResults responseSerializer] responseObjectForResponse:nil
                                                                                                  data:resultData
                                                                                                 error:&error];
    XCTAssertNil(error);
    assertThat(searchResults.results, hasCountOf(resultJSONObjects.count));

    XCTAssertNotNil(searchResults, @"Failed to serialize search results from 'BarackSearch' fixture; %@", error);

    NSSortDescriptor *indexSortDescriptor =
        [NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index)
                                      ascending:YES];

    assertThat(searchResults.results,
               is(equalTo([searchResults.results sortedArrayUsingDescriptors:@[ indexSortDescriptor ]])));

    assertThat(searchResults.searchSuggestion, is(nilValue()));

    assertThat([searchResults redirectMappings], hasCountOf([resultJSON[@"redirects"] count]));
}

@end
