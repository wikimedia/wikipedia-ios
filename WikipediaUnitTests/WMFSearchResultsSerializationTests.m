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

- (void)testSerializesPrefixResultsInOrderOfIndex {
    NSString* fixtureName = @"BarackSearch";
    NSData* resultData = [[self wmf_bundle] wmf_dataFromContentsOfFile:fixtureName ofType:@"json"];

    NSArray<NSDictionary*>* resultJSONObjects =
        [[[[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName] valueForKeyPath:@"query.pages"] allValues];

    NSError* error;
    WMFSearchResults* searchResults = [[WMFSearchResults responseSerializer] responseObjectForResponse:nil
                                                                                                  data:resultData
                                                                                                 error:nil];

    assertThat(searchResults.results, hasCountOf(resultJSONObjects.count));

    XCTAssertNotNil(searchResults, @"Failed to serialize search results from 'BarackSearch' fixture; %@", error);

    NSSortDescriptor* indexSortDescriptor =
        [NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index) ascending:YES];

    assertThat(searchResults.results,
               is(equalTo([searchResults.results sortedArrayUsingDescriptors:@[indexSortDescriptor]])));

    assertThat(searchResults.searchSuggestion, is(nilValue()));
}

@end
