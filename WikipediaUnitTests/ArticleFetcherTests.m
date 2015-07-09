//
//  ArticleFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ArticleFetcher.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKArticle.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "WMFTestFixtureUtilities.h"
#import "SessionSingleton.h"
#import "WMFAsyncTestCase.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface ArticleFetcherTests : XCTestCase

@property (strong, nonatomic) MWKDataStore* tempDataStore;
@property (strong, nonatomic) AFHTTPRequestOperationManager* mockRequestManager;
@property (strong, nonatomic) ArticleFetcher* articleFetcher;
@property (strong, nonatomic) void (^ fetchFinished)(MWKArticle*, NSError*);
@end

@implementation ArticleFetcherTests

- (void)setUp {
    [super setUp];
    self.mockRequestManager = mock([AFHTTPRequestOperationManager class]);
    self.tempDataStore      = [MWKDataStore temporaryDataStore];
}

- (void)tearDown {
    [self.tempDataStore removeFolderAtBasePath];
    self.fetchFinished = nil;
    [super tearDown];
}

- (void)testSuccessfulFetchWritesArticleToDataStore {
    MWKTitle* dummyTitle     = [[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"] titleWithString:@"Foo"];
    MWKArticle* dummyArticle = [self.tempDataStore articleWithTitle:dummyTitle];

    MKTArgumentCaptor* successCaptor = [self mockSuccessfulFetchOfArticle:dummyArticle
                                                              withManager:self.mockRequestManager
                                                                withStore:self.tempDataStore];

    XCTestExpectation* responseExpectation = [self expectationWithDescription:@"articleResponse"];

    @weakify(self)
    self.fetchFinished = ^(MWKArticle* article, NSError* err) {
        @strongify(self)
        assertThat(err, is(nilValue()));
        MWKArticle* savedArticle = [self.tempDataStore articleWithTitle:dummyTitle];
        assertThat(article, is(equalTo(savedArticle)));
        assertThat(@([article isDeeplyEqualToArticle:savedArticle]), isTrue());
        [responseExpectation fulfill];
    };

    [self invokeCapturedSuccessBlock:successCaptor withDataFromFixture:@"Obama"];

    // this is slow, so needs a longer timeout
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFetchingArticleIsIdempotent {
    MWKTitle* dummyTitle     = [[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"] titleWithString:@"Foo"];
    MWKArticle* dummyArticle = [self.tempDataStore articleWithTitle:dummyTitle];

    dispatch_block_t fetch = ^{
        XCTestExpectation* responseExpectation = [self expectationWithDescription:@"articleResponse"];

        AFHTTPRequestOperationManager* manager = mock([AFHTTPRequestOperationManager class]);
        MKTArgumentCaptor* successBlockCaptor  = [self mockSuccessfulFetchOfArticle:dummyArticle
                                                                        withManager:manager
                                                                          withStore:self.tempDataStore];

        self.fetchFinished = ^(MWKArticle* article, NSError* err) {
            [responseExpectation fulfill];
        };

        [self invokeCapturedSuccessBlock:successBlockCaptor withDataFromFixture:@"Obama"];

        // this is slow, so needs a longer timeout
        [self waitForExpectationsWithTimeout:2.0 handler:nil];
    };

    fetch();

    MWKArticle* firstFetchResult = [self.tempDataStore articleWithTitle:dummyTitle];


    fetch();

    MWKArticle* secondFetchResult = [self.tempDataStore articleWithTitle:dummyTitle];

    assertThat(secondFetchResult, is(equalTo(firstFetchResult)));
    assertThat(@([secondFetchResult isDeeplyEqualToArticle:firstFetchResult]),
               describedAs(@"Expected data store to remain the same after fetching the same article twice: \n"
                           "firstResult: %0 \n"
                           "secondResult: %1",
                           isTrue(),
                           [firstFetchResult debugDescription],
                           [secondFetchResult debugDescription], nil));
}

- (MKTArgumentCaptor*)mockSuccessfulFetchOfArticle:(MWKArticle*)article
                                       withManager:(AFHTTPRequestOperationManager*)manager
                                         withStore:(MWKDataStore*)store {
    ArticleFetcher* fetcher = [[ArticleFetcher alloc] init];
    [fetcher fetchSectionsForTitle:article.title inDataStore:store withManager:manager progressBlock:NULL completionBlock:^(MWKArticle* article) {
        if (self.fetchFinished) {
            self.fetchFinished(article, nil);
        }
    } errorBlock:^(NSError* error) {
        if (self.fetchFinished) {
            self.fetchFinished(nil, error);
        }
    }];


    MKTArgumentCaptor* successCaptor = [MKTArgumentCaptor new];
    [MKTVerify(manager)
     GET:[[[SessionSingleton sharedInstance] urlForLanguage:article.title.site.language] absoluteString]
     parameters:anything()
        success:[successCaptor capture]
        failure:anything()];

    return successCaptor;
}

- (void)invokeCapturedSuccessBlock:(MKTArgumentCaptor*)captor withDataFromFixture:(NSString*)fixture {
    void (^ successBlock)(AFHTTPRequestOperation*, id response) = [captor value];
    NSData* jsonData = [[self wmf_bundle] wmf_dataFromContentsOfFile:fixture ofType:@"json"];
    successBlock(nil, jsonData);
}

@end
