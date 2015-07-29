//
//  ArticleFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
//#import "WMFArticleFetcher.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKArticle.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "WMFTestFixtureUtilities.h"
#import "SessionSingleton.h"
#import <Nocilla/Nocilla.h>
//#import "WikipediaUnitTests-Swift.h"
//#import "PromiseKit.h"

@interface ArticleFetcherTests : XCTestCase

@property (strong, nonatomic) MWKDataStore* tempDataStore;
//@property (strong, nonatomic) WMFArticleFetcher* articleFetcher;

@end

@implementation ArticleFetcherTests

- (void)setUp {
    [super setUp];
    self.tempDataStore = [MWKDataStore temporaryDataStore];
//    self.articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.tempDataStore];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [self.tempDataStore removeFolderAtBasePath];
    self.tempDataStore = nil;
//    self.articleFetcher = nil;
    [super tearDown];
}

- (void)testSuccessfulFetchWritesArticleToDataStore {
    MWKSite* site        = [MWKSite siteWithDomain:@"wikipedia.org" language:@"en"];
    MWKTitle* dummyTitle = [site titleWithString:@"Foo"];
    NSURL* url           = [site mobileApiEndpoint];

    MWKArticle* dummyArticle = [self.tempDataStore articleWithTitle:dummyTitle];

    NSString* json = [[self wmf_bundle] wmf_stringFromContentsOfFile:@"Obama" ofType:@"json"];

    stubRequest(@"GET", [url absoluteString]).
    andReturn(200).
    withHeaders(@{@"Content-Type": @"application/json"}).
    withBody(json);

//    XCTestExpectation* responseExpectation = [self expectationWithDescription:@"articleResponse"];
//
//    [self.articleFetcher fetchArticleForPageTitle:dummyTitle progress:NULL].then(^(MWKArticle* article){
//
//        MWKArticle* savedArticle = [self.tempDataStore articleWithTitle:dummyTitle];
//        assertThat(article, is(equalTo(savedArticle)));
//        assertThat(@([article isDeeplyEqualToArticle:savedArticle]), isTrue());
//        [responseExpectation fulfill];
//
//    }).catch(^(NSError* error){
//
//
//
//    });

    // this is slow, so needs a longer timeout
//    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

//- (void)testFetchingArticleIsIdempotent {
//    MWKTitle* dummyTitle     = [[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"] titleWithString:@"Foo"];
//    MWKArticle* dummyArticle = [self.tempDataStore articleWithTitle:dummyTitle];
//
//    dispatch_block_t fetch = ^{
//        XCTestExpectation* responseExpectation = [self expectationWithDescription:@"articleResponse"];
//
//        AFHTTPRequestOperationManager* manager = mock([AFHTTPRequestOperationManager class]);
//        MKTArgumentCaptor* successBlockCaptor  = [self mockSuccessfulFetchOfArticle:dummyArticle
//                                                                        withManager:manager
//                                                                          withStore:self.tempDataStore];
//
//        self.fetchFinished = ^(MWKArticle* article, NSError* err) {
//            [responseExpectation fulfill];
//        };
//
//        [self invokeCapturedSuccessBlock:successBlockCaptor withDataFromFixture:@"Obama"];
//
//        // this is slow, so needs a longer timeout
//        [self waitForExpectationsWithTimeout:2.0 handler:nil];
//    };
//
//    fetch();
//
//    MWKArticle* firstFetchResult = [self.tempDataStore articleWithTitle:dummyTitle];
//
//
//    fetch();
//
//    MWKArticle* secondFetchResult = [self.tempDataStore articleWithTitle:dummyTitle];
//
//    assertThat(secondFetchResult, is(equalTo(firstFetchResult)));
//    assertThat(@([secondFetchResult isDeeplyEqualToArticle:firstFetchResult]),
//               describedAs(@"Expected data store to remain the same after fetching the same article twice: \n"
//                           "firstResult: %0 \n"
//                           "secondResult: %1",
//                           isTrue(),
//                           [firstFetchResult debugDescription],
//                           [secondFetchResult debugDescription], nil));
//}


@end
