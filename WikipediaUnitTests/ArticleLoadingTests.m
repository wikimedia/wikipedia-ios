//
//  ArticleLoadingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 4/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFWebViewController_Private.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFTestFixtureUtilities.h"

#define HC_SHORTHAND 1
#define MOCKITO_SHORTHAND 1

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@interface ArticleLoadingTests : XCTestCase
@property WMFWebViewController* webVC;
@property SessionSingleton* session;
@end

@implementation ArticleLoadingTests

- (void)setUp {
    [super setUp];

    self.session = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
    self.webVC   = [[WMFWebViewController alloc] initWithSession:self.session];

    // disable TOC stuff since it breaks when the WebVC isn't properly attached to a window/parent-VC
}

- (void)tearDown {
    [self.session.dataStore removeFolderAtBasePath];
    [super tearDown];
}

//- (void)testReloadDoesNotAffectHistory {
//    MWKArticle* dummyArticle = [self storeDummyArticleWithTitle:@"foo"];
//    self.session.currentArticle = dummyArticle;
//
//    [self.webVC navigateToPage:dummyArticle.title
//               discoveryMethod:MWKHistoryDiscoveryMethodReloadFromNetwork];
//
//    // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title
//
//    [self.webVC fetchFinished:mock([ArticleFetcher class])
//                  fetchedData:nil //< unused
//                       status:FETCH_FINAL_STATUS_SUCCEEDED
//                        error:nil];
//
//    assertThat(self.session.currentArticle, is(dummyArticle));
//    assertThat(@(self.session.userDataStore.historyList.length), is(@0));
//}
//
//- (void)testSuccessfulNavigationStoredInHistory {
//    // should be true for every discovery method _except_ back/forward and reload
//    MWKHistoryDiscoveryMethod methods[5] = {MWKHistoryDiscoveryMethodLink,
//                                            MWKHistoryDiscoveryMethodRandom,
//                                            MWKHistoryDiscoveryMethodSaved,
//                                            MWKHistoryDiscoveryMethodSearch,
//                                            MWKHistoryDiscoveryMethodUnknown};
//
//    for (NSUInteger i = 0; i < 5; i++) {
//        MWKHistoryDiscoveryMethod currentMethod = methods[i];
//
//        MWKArticle* dummyArticle = [self storeDummyArticleWithTitle:@(i).stringValue];
//
//        [self.webVC navigateToPage:dummyArticle.title discoveryMethod:currentMethod];
//
//        // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title
//
//        [self.webVC fetchFinished:mock([ArticleFetcher class])
//                      fetchedData:nil //< unused
//                           status:FETCH_FINAL_STATUS_SUCCEEDED
//                            error:nil];
//
//        assertThat(self.session.currentArticle, is(dummyArticle));
//        MWKHistoryEntry* mostRecentEntry = self.session.userDataStore.historyList.mostRecentEntry;
//        assertThat(mostRecentEntry.title, is(dummyArticle.title));
//        assertThat(@(mostRecentEntry.discoveryMethod), is(@(currentMethod)));
//        assertThat(@(self.session.userDataStore.historyList.length), is(@(i + 1)));
//    }
//}
//
//- (void)testSuccessfulBackForwardNavigationIsNotStoredInHistory {
//    MWKArticle* dummyArticle = [self storeDummyArticleWithTitle:@"No history for you!"];
//
//    [self.webVC navigateToPage:dummyArticle.title
//               discoveryMethod:MWKHistoryDiscoveryMethodBackForward];
//
//    // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title
//
//    [self.webVC fetchFinished:mock([ArticleFetcher class])
//                  fetchedData:nil //< unused
//                       status:FETCH_FINAL_STATUS_SUCCEEDED
//                        error:nil];
//
//    assertThat(self.session.currentArticle, is(dummyArticle));
//    assertThat(@(self.session.userDataStore.historyList.length), is(@0));
//}
//
//- (void)testFailedNavigationNotStoredInHistory {
//    MWKArticle* originalArticle = [self storeDummyArticleWithTitle:@"original"];
//
//    self.session.currentArticle = originalArticle;
//
//    // should be true for every discovery
//    MWKHistoryDiscoveryMethod methods[7] = {MWKHistoryDiscoveryMethodReloadFromNetwork,
//                                            MWKHistoryDiscoveryMethodReloadFromCache,
//                                            MWKHistoryDiscoveryMethodLink,
//                                            MWKHistoryDiscoveryMethodRandom,
//                                            MWKHistoryDiscoveryMethodSaved,
//                                            MWKHistoryDiscoveryMethodSearch,
//                                            MWKHistoryDiscoveryMethodUnknown,
//                                            MWKHistoryDiscoveryMethodBackForward};
//
//    FetchFinalStatus finalStatuses[2] = {FETCH_FINAL_STATUS_FAILED, FETCH_FINAL_STATUS_CANCELLED};
//
//    for (NSUInteger i = 0; i < 7; i++) {
//        MWKHistoryDiscoveryMethod currentMethod = methods[i];
//
//        MWKTitle* failedTitle =
//            [MWKTitle titleWithString:[NSString stringWithFormat:@"failed-%lu", (unsigned long)i]
//                                 site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
//
//        for (NSUInteger j = 0; j < 2; j++) {
//            FetchFinalStatus finalStatus = finalStatuses[j];
//            [self.webVC navigateToPage:failedTitle discoveryMethod:currentMethod];
//
//            // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title
//
//            [self.webVC fetchFinished:mock([ArticleFetcher class])
//                          fetchedData:nil //< unused
//                               status:finalStatus
//                                error:mock([NSError class])];
//
//            #warning FIXME: the currentArticle is corrupted after a failed fetch!!!!!
//            //assertThat(self.session.currentArticle, is(originalArticle));
//            assertThat(@(self.session.userDataStore.historyList.length), is(equalToUnsignedInt(0)));
//        }
//    }
//}
//
#pragma mark - Utils

- (MWKArticle*)storeDummyArticleWithTitle:(NSString*)title {
    MWKTitle* dummyTitle =
        [MWKTitle titleWithString:title site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];

    MWKArticle* dummyArticle =
        [[MWKArticle alloc] initWithTitle:dummyTitle dataStore:self.session.dataStore];

    // least-tedious way to create a testing article that can be persisted
    [dummyArticle importMobileViewJSON:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [dummyArticle save];
    return dummyArticle;
}

@end
