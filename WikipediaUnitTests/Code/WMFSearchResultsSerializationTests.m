#import <XCTest/XCTest.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import "WMFSearchResults+ResponseSerializer.h"
#import "MWKSearchResult.h"

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
    XCTAssertEqual(searchResults.results.count, 0);
    XCTAssertEqual(searchResults.redirectMappings.count, 0);
    XCTAssertEqualObjects(searchResults.searchSuggestion, [noResultJSON valueForKeyPath:@"query.searchinfo.suggestion"]);
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
    XCTAssertEqual(searchResults.results.count, resultJSONObjects.count);

    XCTAssertNotNil(searchResults, @"Failed to serialize search results from 'BarackSearch' fixture; %@", error);

    NSSortDescriptor *indexSortDescriptor =
        [NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index)
                                      ascending:YES];

    XCTAssert([searchResults.results isEqual:[searchResults.results sortedArrayUsingDescriptors:@[indexSortDescriptor]]]);

    XCTAssert(searchResults.searchSuggestion == nil);

    XCTAssertEqual([searchResults redirectMappings].count, [resultJSON[@"redirects"] count]);
}

@end
