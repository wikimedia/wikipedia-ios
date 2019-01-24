#import <XCTest/XCTest.h>
#import "MWKSearchResult.h"
#import "WMFSearchResults.h"

@interface WMFSearchResultsSerializationTests : XCTestCase

@end

@implementation WMFSearchResultsSerializationTests

- (void)testResultsAndRedirectsAreNonnullForZeroResultResponse {
    id noResultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"NoSearchResultsWithSuggestion"];
    NSDictionary *query = noResultJSON[@"query"];
    NSError *mantleError = nil;
    WMFSearchResults *searchResults = [MTLJSONAdapter modelOfClass:[WMFSearchResults class] fromJSONDictionary:query error:&mantleError];
    XCTAssertNil(mantleError);
    XCTAssertEqual(searchResults.results.count, 0);
    XCTAssertEqual(searchResults.redirectMappings.count, 0);
    XCTAssertEqualObjects(searchResults.searchSuggestion, [noResultJSON valueForKeyPath:@"query.searchinfo.suggestion"]);
}

- (void)testSerializesPrefixResultsInOrderOfIndex {
    NSString *fixtureName = @"BarackSearch";
    NSDictionary *resultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"query"];

    NSArray<NSDictionary *> *resultJSONObjects = [resultJSON[@"pages"] allValues];

    NSError *mantleError = nil;
    WMFSearchResults *searchResults = [MTLJSONAdapter modelOfClass:[WMFSearchResults class] fromJSONDictionary:resultJSON error:&mantleError];
    XCTAssertNil(mantleError);
    XCTAssertEqual(searchResults.results.count, resultJSONObjects.count);

    XCTAssertNotNil(searchResults, @"Failed to serialize search results from 'BarackSearch' fixture; %@", mantleError);

    NSSortDescriptor *indexSortDescriptor =
        [NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index)
                                      ascending:YES];

    XCTAssert([searchResults.results isEqual:[searchResults.results sortedArrayUsingDescriptors:@[indexSortDescriptor]]]);

    XCTAssert(searchResults.searchSuggestion == nil);

    XCTAssertEqual([searchResults redirectMappings].count, [resultJSON[@"redirects"] count]);
}

@end
