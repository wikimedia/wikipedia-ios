//
//  MWKSiteInfoFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "MWKSite.h"
#import "MWKSiteInfo.h"
#import "MWKSiteInfoFetcher.h"
#import "XCTestCase+WMFLocaleTesting.h"
#import "NSArray+WMFShuffle.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "WMFTestFixtureUtilities.h"
#import "AFHTTPRequestOperationManager+UniqueRequests.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSiteInfoFetcherTests : WMFAsyncTestCase
@property (strong, nonatomic) MWKSiteInfoFetcher* fetcher;
@end

@implementation MWKSiteInfoFetcherTests

- (void)setUp {
    [super setUp];
    self.fetcher = [MWKSiteInfoFetcher new];
}

- (void)testENWikiFixture {
    [self runSuccessfulCallbackTestWithFixture:@"ENWikiSiteInfo" site:[MWKSite siteWithLanguage:@"en"]];
}

- (void)testNOWikiFixture {
    [self runSuccessfulCallbackTestWithFixture:@"NOWikiSiteInfo" site:[MWKSite siteWithLanguage:@"no"]];
}

- (void)testErrorHandling {
    AFHTTPRequestOperationManager* mockReqManager =
        mock([[NSBundle mainBundle] classNamed:NSStringFromClass([AFHTTPRequestOperationManager class])]);
    self.fetcher.requestManager = mockReqManager;

    MWKSite* testSite = [MWKSite siteWithCurrentLocale];

    NSError* expectedError = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];

    [self.fetcher fetchInfoForSite:testSite
                           success:^(MWKSiteInfo* siteInfo) {}
                           failure:^(NSError* e){
        assertThat(e, is(expectedError));
    }];

    MKTArgumentCaptor* failureBlockCaptor = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(mockReqManager) wmf_idempotentGET:testSite.apiEndpoint.absoluteString
                                      parameters:anything()
                                         success:anything()
                                         failure:[failureBlockCaptor capture]];
    void (^ failureCallback)(AFHTTPRequestOperation* op, NSError* err) = [failureBlockCaptor value];
    failureCallback(nil, expectedError);
}

- (void)runSuccessfulCallbackTestWithFixture:(NSString*)fixture site:(MWKSite*)testSite {
    AFHTTPRequestOperationManager* mockReqManager =
        mock([[NSBundle mainBundle] classNamed:NSStringFromClass([AFHTTPRequestOperationManager class])]);
    self.fetcher.requestManager = mockReqManager;

    NSDictionary* fixtureJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixture];

    XCTestExpectation* successfulFetchExpectation = [self expectationWithDescription:@"successCallback"];

    [self.fetcher fetchInfoForSite:testSite
                           success:^(MWKSiteInfo* siteInfo) {
        assertThat(siteInfo.mainPageTitleText, is([fixtureJSON valueForKeyPath:@"query.general.mainpage"]));
        [successfulFetchExpectation fulfill];
    }
                           failure:^(NSError* e){}];

    MKTArgumentCaptor* successBlockCaptor = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(mockReqManager) wmf_idempotentGET:testSite.apiEndpoint.absoluteString
                                      parameters:anything()
                                         success:[successBlockCaptor capture]
                                         failure:anything()];
    void (^ responseCallback)(AFHTTPRequestOperation* op, NSDictionary* json) = [successBlockCaptor value];
    responseCallback(nil, fixtureJSON);

    WaitForExpectations();
}

#if 0
// Disabled since doing network I/O is slow. Run manually if necessary
- (void)testRealFetchOfPopularLocales {
    [self runTestWithLocales:@[@"en_US", @"fr_FR", @"en_GB"]];
}

#endif

#if 0
// Warning, this test is flaky by nature. Only run manually and don't commit w/ it enabled.
- (void)testRealFetchOfRandomLocales {
    [self runTestWithLocales:
     [[[NSLocale availableLocaleIdentifiers]
       wmf_shuffledCopy]
      subarrayWithRange:NSMakeRange(0, 100)]];
}

#endif

- (void)runTestWithLocales:(NSArray*)localeIdentifiers {
    NSMutableArray* errors = [NSMutableArray new];
    [self wmf_runParallelTestsWithLocales:localeIdentifiers
                                    block:^(NSLocale* locale, XCTestExpectation* expectation) {
        MWKSite* site = [MWKSite siteWithLocale:locale];
        [self.fetcher fetchInfoForSite:site
                               success:^(MWKSiteInfo* info) {
            NSLog(@"Site info for %@: %@", locale.localeIdentifier, info);
            [expectation fulfill];
        }
                               failure:^(NSError* error) {
            @synchronized(errors) {
                [errors addObject:@[locale.localeIdentifier, error]];
            }
            [expectation fulfill];
        }];
    }];
    XCTAssert(errors.count == 0, @"Failed to fetch site info for locales: %@", errors);
}

@end
