//
//  WMFFeaturedItemFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+PromiseKit.h"
#import "WMFENFeaturedTitleFetcher.h"
#import "MWKSearchResult.h"

@interface WMFENFeaturedTitleFetcherTests : XCTestCase

@property (nonatomic, strong) WMFENFeaturedTitleFetcher* fetcher;

@end

@implementation WMFENFeaturedTitleFetcherTests

- (void)setUp {
    [super setUp];
    self.fetcher = [[WMFENFeaturedTitleFetcher alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

#if 0
// Don't commit with this enabled, sends an actual network request
// TODO: use fixture
- (void)testExample {
    expectResolutionWithTimeout(5, ^{
        return [self.fetcher fetchFeedItemTitleForSite:[MWKSite siteWithLanguage:@"en"] date:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]]
        .then(^ (MWKSearchResult* result) {
            DDLogInfo(@"Got extract: %@", result.description);
        });
    });
}
#endif

@end
