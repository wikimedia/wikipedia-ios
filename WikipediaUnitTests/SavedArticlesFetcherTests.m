//
//  SavedArticlesFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SavedArticlesFetcher_Testing.h"
#import "WMFArticleFetcher.h"
#import "MWKSavedPageList.h"
#import "MWKTitle.h"
#import "MWKSavedPageEntry.h"

// Test Utils
#import "WMFAsyncTestCase.h"
#import "WMFTestFixtureUtilities.h"
#import "XCTestCase+PromiseKit.h"
#import "MWKDataStore+TemporaryDataStore.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

typedef void(^SavedArticlesFetcherDidFetchArticleBlock)(MWKArticle*, CGFloat, NSError*);

/**
 *  Verify the proper download & error handling of the SavedArticlesFetcher.
 *
 *  @note @c WMFArticleFetcher is responsible for both fetching <b>and</b> persisting articles. We are mocking it
 *        here for simplicity, but felt it was worth noting that we are not checking the data store here since we 
 *        take for granted that the successful resolution of a promise from @c WMFArticleFetcher means the article was
 *        written successfully to disk.
 */
@interface SavedArticlesFetcherTests : WMFAsyncTestCase
<SavedArticlesFetcherDelegate>

@property (nonatomic, strong) SavedArticlesFetcher* savedArticlesFetcher;

@property (nonatomic, strong) WMFArticleFetcher* mockArticleFetcher;

@property (nonatomic, strong) MWKDataStore* tempDataStore;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) NSMutableArray<SavedArticlesFetcherDidFetchArticleBlock>* expectedArticles;

@property (nonatomic, strong) void(^expectedFetchFinishedError)(NSError*);

@end

@implementation SavedArticlesFetcherTests

- (void)setUp {
    [super setUp];
    self.expectedArticles = [NSMutableArray new];
    self.expectedFetchFinishedError = nil;
    self.tempDataStore = [MWKDataStore temporaryDataStore];
    self.mockArticleFetcher = mock([WMFArticleFetcher class]);
    self.savedArticlesFetcher = [[SavedArticlesFetcher alloc] initWithArticleFetcher:self.mockArticleFetcher];
    self.savedArticlesFetcher.fetchFinishedDelegate = self;
}

- (void)tearDown {
    // technically neither of these should happen since we're using expectations, but added as a fail-safe
    // to ensure expectations work properly
    XCTAssert(self.expectedArticles.count == 0, @"Not all expected articles were retrieved!");
    XCTAssertNil(self.expectedFetchFinishedError, @"fetchFinished: callback not invoked!");

    [self.tempDataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testShouldStartDownloadingAnArticleWhenItIsSaved {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchSavedPageList:self.savedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    MWKArticle* stubbedArticle =
        [[MWKArticle alloc]
         initWithTitle:dummyTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToGetArticle:stubbedArticle atProgress:1.0 error:nil];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();
}

- (void)testShouldReportDownloadErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchSavedPageList:self.savedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToGetArticle:nil atProgress:1.0 error:downloadError];

    [self expectFetcherToFinishWithError:downloadError];

    WaitForExpectations();
}

- (void)testShouldStopDownloadingAnArticleWhenItIsDeleted {
}

- (void)testShouldDownloadMultipleArticles {
}

- (void)testShouldNotDownloadCachedArticles {
}

#pragma mark - Utils

- (MWKSavedPageList*)savedPageList {
    if (!_savedPageList) {
        self.savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self.tempDataStore];
    }
    return _savedPageList;
}

- (void)stubListWithEntries:(NSUInteger)numEntries {
    for (NSUInteger e = 0; e < numEntries; e++) {
        MWKTitle* title = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/Foo_%lu", e]]];
        MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
        [self.savedPageList addEntry:entry];
    }
    PMKHang([self.savedPageList save]);
}

- (void)expectFetcherToGetArticle:(MWKArticle*)expectedArticle
                       atProgress:(CGFloat)expectedProgress
                            error:(NSError*)expectedError {
    XCTestExpectation* fetchArticleExpectation =
        [self expectationWithDescription:[NSString stringWithFormat:@"Fetch %@", expectedArticle.title ? : expectedError]];
    @weakify(self);
    [self.expectedArticles addObject:^(MWKArticle* article, CGFloat progress, NSError* error) {
        @strongify(self);
        XCTAssertEqualObjects(article, expectedArticle);
        XCTAssertEqual(progress, expectedProgress);
        XCTAssertEqualObjects(error, expectedError);
        [fetchArticleExpectation fulfill];
    }];
}

- (void)expectFetcherToFinishWithError:(NSError*)error {
    XCTestExpectation* fetchFinishedExpectation = [self expectationWithDescription:@"fetch finished"];
    @weakify(self);
    self.expectedFetchFinishedError = ^(NSError* e) {
        @strongify(self);
        XCTAssertEqualObjects(e, error);
        [fetchFinishedExpectation fulfill];
    };
}

#pragma mark - SavedArticlesFetcherDelegate

- (void)savedArticlesFetcher:(SavedArticlesFetcher *)savedArticlesFetcher
             didFetchArticle:(MWKArticle *)article
                    progress:(CGFloat)progress
                       error:(NSError *)error {
    XCTAssert(self.expectedArticles.count > 0, @"Received didFetchArticle callback when none expected.");
    SavedArticlesFetcherDidFetchArticleBlock callback = self.expectedArticles.firstObject;
    [self.expectedArticles removeObjectAtIndex:0];
    callback(article, progress, error);
}

- (void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError *)error {
    XCTAssertNotNil(self.expectedFetchFinishedError, @"Wasn't expecting a fetchFinished callback!");
    self.expectedFetchFinishedError(error);
    self.expectedFetchFinishedError = nil;
}

@end
