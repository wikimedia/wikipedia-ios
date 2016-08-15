//
//  WMFSearchResultsMergeTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "WMFSearchResults.h"
#import "MWKSearchResult.h"
#import "MWKSearchRedirectMapping.h"
#import "NSNumber+MWKTitleNamespace.h"

static MWKSearchResult *dummySearchResultWithIndex(NSUInteger index) {
    static NSUInteger articleId = 0;
    // increase articleId monotonically to make them unique
    return [[MWKSearchResult alloc] initWithArticleID:articleId++
                                                revID:0
                                         displayTitle:@"foo"
                                  wikidataDescription:@"bar"
                                              extract:@"baz"
                                         thumbnailURL:[NSURL URLWithString:@"http://foo.bar/baz"]
                                                index:@(index)
                                     isDisambiguation:NO
                                               isList:NO
                                       titleNamespace:@(MWKTitleNamespaceMain)];
}

QuickSpecBegin(WMFSearchResultMergeTests)

    describe(@"merging results", ^{
      void (^verifyKVOInsertionOfResults)(WMFSearchResults *, WMFSearchResults *) = ^(WMFSearchResults *r1, WMFSearchResults *r2) {
        NSArray *originalResults = r1.results;
        [self keyValueObservingExpectationForObject:r1
                                            keyPath:WMF_SAFE_KEYPATH(r1, results)
                                            handler:^BOOL(id _Nonnull observedObject, NSDictionary *_Nonnull change) {
                                              return [change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion && [change[NSKeyValueChangeIndexesKey] containsIndexesInRange:NSMakeRange(originalResults.count, r2.results.count)];
                                            }];
      };
      it(@"should preserve result ordering, putting original results first", ^{
        NSArray *originalResults = @[ dummySearchResultWithIndex(0),
                                      dummySearchResultWithIndex(1),
                                      dummySearchResultWithIndex(2) ];
        WMFSearchResults *r1 =
            [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                                 results:originalResults
                                        searchSuggestion:@"bar"
                                        redirectMappings:@[]];
        WMFSearchResults *r2 =
            [[WMFSearchResults alloc] initWithSearchTerm:@"baz"
                                                 results:@[ dummySearchResultWithIndex(0),
                                                            dummySearchResultWithIndex(1),
                                                            dummySearchResultWithIndex(2) ]
                                        searchSuggestion:@"buz"
                                        redirectMappings:@[]];

        verifyKVOInsertionOfResults(r1, r2);

        [r1 mergeValuesForKeysFromModel:r2];

        expect([r1.results subarrayWithRange:NSMakeRange(0, originalResults.count)])
            .toWithDescription(equal(originalResults), @"put original results first, in the same order");

        expect([r1.results subarrayWithRange:NSMakeRange(originalResults.count, r2.results.count)])
            .toWithDescription(equal(r2.results), @"put merged results last, in the same order");
      });

      it(@"should not insert results already present in the original", ^{
        NSArray *originalResults = @[ dummySearchResultWithIndex(0) ];
        NSArray *newResults = @[
            dummySearchResultWithIndex(0),
            dummySearchResultWithIndex(1),
            dummySearchResultWithIndex(2)
        ];

        WMFSearchResults *r1 =
            [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                                 results:originalResults
                                        searchSuggestion:@"bar"
                                        redirectMappings:@[]];

        WMFSearchResults *r2 =
            [[WMFSearchResults alloc] initWithSearchTerm:@"baz"
                                                 results:[originalResults arrayByAddingObjectsFromArray:newResults]
                                        searchSuggestion:@"buz"
                                        redirectMappings:@[]];

        verifyKVOInsertionOfResults(r1, r2);

        [r1 mergeValuesForKeysFromModel:r2];

        expect(r1.results.firstObject).to(equal(originalResults.firstObject));

        expect([r1.results subarrayWithRange:NSMakeRange(originalResults.count, r2.results.count - 1)])
            .to(equal(newResults));
      });
    });

describe(@"merging redirect mappings", ^{
  it(@"should omit mappings already present in the original", ^{
    NSArray *originalMappings = @[ [MWKSearchRedirectMapping mappingFromTitle:@"foo" toTitle:@"bar"] ];
    NSArray *newMappings = @[ [MWKSearchRedirectMapping mappingFromTitle:@"baz" toTitle:@"buz"] ];
    NSArray *joinedMappings = [originalMappings arrayByAddingObjectsFromArray:newMappings];

    WMFSearchResults *r1 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@"bar"
                                    redirectMappings:originalMappings];

    WMFSearchResults *r2 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@"bar"
                                    redirectMappings:joinedMappings];

    [r1 mergeValuesForKeysFromModel:r2];

    expect(@(r1.redirectMappings.count)).to(equal(@(originalMappings.count + newMappings.count)));
    expect(r1.redirectMappings).to(equal(joinedMappings));
  });
});

describe(@"merging search suggestion", ^{
  it(@"should preserve the original suggestion if there was one", ^{
    NSString *originalSuggestion = @"bar";

    WMFSearchResults *r1 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:originalSuggestion
                                    redirectMappings:@[]];

    WMFSearchResults *r2 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@"baz"
                                    redirectMappings:@[]];

    [r1 mergeValuesForKeysFromModel:r2];

    expect(r1.searchSuggestion).to(equal(originalSuggestion));
  });

  it(@"should set the new suggestion if the original was nil", ^{
    WMFSearchResults *r1 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:nil
                                    redirectMappings:@[]];

    WMFSearchResults *r2 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@"baz"
                                    redirectMappings:@[]];

    [r1 mergeValuesForKeysFromModel:r2];

    expect(r1.searchSuggestion).to(equal(r2.searchSuggestion));
  });

  it(@"should set the new suggestion if the original was empty", ^{
    WMFSearchResults *r1 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@""
                                    redirectMappings:@[]];

    WMFSearchResults *r2 =
        [[WMFSearchResults alloc] initWithSearchTerm:@"foo"
                                             results:@[]
                                    searchSuggestion:@"baz"
                                    redirectMappings:@[]];

    [r1 mergeValuesForKeysFromModel:r2];

    expect(r1.searchSuggestion).to(equal(r2.searchSuggestion));
  });
});

QuickSpecEnd
