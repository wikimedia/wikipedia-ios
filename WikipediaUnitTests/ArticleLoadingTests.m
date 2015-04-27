//
//  ArticleLoadingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 4/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WebViewController_Private.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFTestFixtureUtilities.h"

#define HC_SHORTHAND 1
#define MOCKITO_SHORTHAND 1

#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@interface ArticleLoadingTests : XCTestCase
@property WebViewController* webVC;
@property SessionSingleton* session;
@end

@implementation ArticleLoadingTests

- (void)setUp {
    [super setUp];

    self.session = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
    self.webVC   = [[WebViewController alloc] initWithSession:self.session];

    // disable TOC stuff since it breaks when the WebVC isn't properly attached to a window/parent-VC
    self.webVC.unsafeToToggleTOC = YES;
}

- (void)tearDown {
    [self.session.dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testSuccessfulNavigationStoredInHistory {
    // should be true for every discovery method _except_ back/forward
    MWKHistoryDiscoveryMethod methods[5] = {MWK_DISCOVERY_METHOD_LINK,
                                            MWK_DISCOVERY_METHOD_RANDOM,
                                            MWK_DISCOVERY_METHOD_SAVED,
                                            MWK_DISCOVERY_METHOD_SEARCH,
                                            MWK_DISCOVERY_METHOD_UNKNOWN};

    for (NSUInteger i = 0; i < 5; i++) {
        MWKHistoryDiscoveryMethod currentMethod = methods[i];

        MWKArticle* dummyArticle = [self storeDummyArticleWithTitle:@(i).stringValue];
        dummyArticle.needsRefresh = YES;

        [self.webVC navigateToPage:dummyArticle.title discoveryMethod:currentMethod showLoadingIndicator:YES];

        // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title

        [self.webVC fetchFinished:mock([ArticleFetcher class])
                      fetchedData:nil //< unused
                           status:FETCH_FINAL_STATUS_SUCCEEDED
                            error:nil];

        assertThat(self.session.currentArticle, is(dummyArticle));
        MWKHistoryEntry* mostRecentEntry = self.session.userDataStore.historyList.mostRecentEntry;
        assertThat(mostRecentEntry.title, is(dummyArticle.title));
        assertThat(@(mostRecentEntry.discoveryMethod), is(@(currentMethod)));
        assertThat(@(self.session.userDataStore.historyList.length), is(@(i + 1)));
    }
}

- (void)testSuccessfulBackForwardNavigationIsNotStoredInHistory {
    MWKArticle* dummyArticle = [self storeDummyArticleWithTitle:@"No history for you!"];
    dummyArticle.needsRefresh = YES;

    [self.webVC navigateToPage:dummyArticle.title
               discoveryMethod:MWK_DISCOVERY_METHOD_BACKFORWARD
          showLoadingIndicator:YES];

    // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title

    [self.webVC fetchFinished:mock([ArticleFetcher class])
                  fetchedData:nil //< unused
                       status:FETCH_FINAL_STATUS_SUCCEEDED
                        error:nil];

    assertThat(self.session.currentArticle, is(dummyArticle));
    assertThat(@(self.session.userDataStore.historyList.length), is(@0));
}

- (void)testFailedNavigationNotStoredInHistory {
    MWKArticle* originalArticle = [self storeDummyArticleWithTitle:@"original"];
    originalArticle.needsRefresh = YES;

    self.session.currentArticle = originalArticle;

    // should be true for every discovery
    MWKHistoryDiscoveryMethod methods[6] = {MWK_DISCOVERY_METHOD_LINK,
                                            MWK_DISCOVERY_METHOD_RANDOM,
                                            MWK_DISCOVERY_METHOD_SAVED,
                                            MWK_DISCOVERY_METHOD_SEARCH,
                                            MWK_DISCOVERY_METHOD_UNKNOWN,
                                            MWK_DISCOVERY_METHOD_BACKFORWARD};

    FetchFinalStatus finalStatuses[2] = {FETCH_FINAL_STATUS_FAILED, FETCH_FINAL_STATUS_CANCELLED};

    for (NSUInteger i = 0; i < 6; i++) {
        MWKHistoryDiscoveryMethod currentMethod = methods[i];

        MWKTitle* failedTitle =
            [MWKTitle titleWithString:[NSString stringWithFormat:@"failed-%u", i]
                                 site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];

        for (NSUInteger j = 0; j < 2; j++) {
            FetchFinalStatus finalStatus = finalStatuses[j];
            [self.webVC navigateToPage:failedTitle discoveryMethod:currentMethod showLoadingIndicator:YES];

            // TODO: verify that mock article fetcher gets a call to fetch article w/ mock title

            [self.webVC fetchFinished:mock([ArticleFetcher class])
                          fetchedData:nil //< unused
                               status:finalStatus
                                error:mock([NSError class])];

            #warning FIXME: the currentArticle is corrupted after a failed fetch!!!!!
            //assertThat(self.session.currentArticle, is(originalArticle));
            assertThat(@(self.session.userDataStore.historyList.length), is(equalToUnsignedInt(0)));
        }
    }
}

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
