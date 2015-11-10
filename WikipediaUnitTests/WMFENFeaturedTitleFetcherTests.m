//
//  WMFFeaturedItemFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+PromiseKit.h"
#import "WMFEnglishFeaturedTitleFetcher.h"
#import "MWKSearchResult.h"

#import <Nocilla/LSNocilla.h>

@interface WMFENFeaturedTitleFetcherTests : XCTestCase

@property (nonatomic, strong) WMFEnglishFeaturedTitleFetcher* fetcher;

@end

@implementation WMFENFeaturedTitleFetcherTests

- (void)setUp {
    [super setUp];
    self.fetcher = [[WMFEnglishFeaturedTitleFetcher alloc] init];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)testExample {
    NSRegularExpression* tfaTitleRequest =
        [NSRegularExpression regularExpressionWithPattern:@"https://en\\.m\\.wikipedia\\.org.*TFA_title.*" options:0 error:nil];

    // expected title matches the one in the JSON fixture
    NSRegularExpression* previewRequest =
        [NSRegularExpression regularExpressionWithPattern:@"https://en\\.m\\.wikipedia\\.org.*titles=Mackensen-class_battlecruiser.*" options:0 error:nil];

    stubRequest(@"GET", tfaTitleRequest)
    .andReturn(200)
    .withHeader(@"Content-Type", @"application/json")
    .withBody([[self wmf_bundle] wmf_stringFromContentsOfFile:@"TFATitleExtract" ofType:@"json"]);

    stubRequest(@"GET", previewRequest)
    .andReturn(200)
    .withHeader(@"Content-Type", @"application/json")
    .withBody([[self wmf_bundle] wmf_stringFromContentsOfFile:@"TitlePreviewQuery" ofType:@"json"]);

    expectResolution(^AnyPromise* {
        return [self.fetcher featuredArticlePreviewForDate:nil]
        .then(^(MWKSearchResult* result) {
            XCTAssertEqualObjects(result.displayTitle, @"Mackensen-class battlecruiser");
        });
    });
}

@end
