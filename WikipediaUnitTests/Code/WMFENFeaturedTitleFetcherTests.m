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
    NSDateComponents* testDateComponents = [[NSDateComponents alloc] init];
    testDateComponents.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
    testDateComponents.month    = 11;
    testDateComponents.day      = 10;
    testDateComponents.year     = 2015;

    NSString* testDatePattern = @"https://en\\.wikipedia\\.org.*TFA_title/November%2010%2C%202015.*";

    NSRegularExpression* tfaTitleRequest =
        [NSRegularExpression regularExpressionWithPattern:testDatePattern options:0 error:nil];

    // expected title matches the one in the JSON fixture
    NSRegularExpression* previewRequest =
        [NSRegularExpression regularExpressionWithPattern:@"https://en\\.wikipedia\\.org.*titles=Mackensen-class%20battlecruiser.*" options:0 error:nil];

    stubRequest(@"GET", tfaTitleRequest)
    .andReturn(200)
    .withHeader(@"Content-Type", @"application/json")
    .withBody([[self wmf_bundle] wmf_stringFromContentsOfFile:@"TFATitleExtract" ofType:@"json"]);

    stubRequest(@"GET", previewRequest)
    .andReturn(200)
    .withHeader(@"Content-Type", @"application/json")
    .withBody([[self wmf_bundle] wmf_stringFromContentsOfFile:@"TitlePreviewQuery" ofType:@"json"]);

    expectResolution(^AnyPromise* {
        return [self.fetcher fetchFeaturedArticlePreviewForDate:[testDateComponents date]]
        .then(^(MWKSearchResult* result) {
            XCTAssertEqualObjects(result.displayTitle, @"Mackensen-class battlecruiser");
        });
    });
}

@end
