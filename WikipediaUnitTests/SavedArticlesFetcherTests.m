//
//  SavedArticlesFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SavedArticlesFetcherTests.h"

@implementation SavedArticlesFetcherTests

- (void)setUp {
    [super setUp];
    self.downloadErrors                             = [NSMutableDictionary new];
    self.downloadedArticles                         = [NSMutableArray new];
    self.expectedFetchFinishedError                 = nil;
    self.tempDataStore                              = [MWKDataStore temporaryDataStore];
    self.mockArticleFetcher                         = mock([WMFArticleFetcher class]);
    self.savedArticlesFetcher                       = [[SavedArticlesFetcher alloc] initWithArticleFetcher:self.mockArticleFetcher];
    self.savedArticlesFetcher.fetchFinishedDelegate = self;
}

- (void)tearDown {
    XCTAssertNil(self.expectedFetchFinishedError, @"fetchFinished: callback not invoked!");
    [self.tempDataStore removeFolderAtBasePath];
    [super tearDown];
}

#pragma mark - Downloading

- (void)testStartDownloadingArticleWhenAddedToList {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    MWKArticle* stubbedArticle =
        [[MWKArticle alloc]
         initWithTitle:dummyTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testStartDownloadingUncachedArticleAlreadyInList {
    [self stubListWithEntries:1];

    MWKTitle* uncachedEntryTitle = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];

    MWKArticle* stubbedArticle =
        [[MWKArticle alloc]
         initWithTitle:uncachedEntryTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:uncachedEntryTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testCorrectProgressForMultipleSuccessfulDownloads {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* firstArticle =
        [[MWKArticle alloc]
         initWithTitle:firstTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle =
        [[MWKArticle alloc]
         initWithTitle:secondTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];


    [given([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:firstArticle]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    assertThat(self.downloadedArticles, is(@[firstArticle, secondArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testSkipsCachedArticles {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* firstArticle =
        [[MWKArticle alloc]
         initWithTitle:firstTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [firstArticle save];
    NSAssert(firstArticle.isCached, @"Test depends on article being considered cached after save!");

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle =
        [[MWKArticle alloc]
         initWithTitle:secondTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];


    [given([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    assertThat(self.downloadedArticles, is(@[secondArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

#pragma mark - Error Handling

- (void)testReportDownloadErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:downloadError];

    WaitForExpectations();

    assertThat(self.downloadedArticles, isEmpty());
    assertThat(self.downloadErrors, is(@{dummyTitle: downloadError}));
}

- (void)testContinuesDownloadingIfArticleDownloadFails {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle =
        [[MWKArticle alloc]
         initWithTitle:secondTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    [self expectFetcherToFinishWithError:downloadError];

    WaitForExpectations();

    assertThat(self.downloadedArticles, is(@[secondArticle]));
    assertThat(self.downloadErrors, is(@{firstTitle: downloadError}));
}

#pragma mark - Cancellation

- (void)testStopDownloadingAnArticleWhenItIsDeleted {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle =
        [[MWKArticle alloc]
         initWithTitle:secondTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];

    __block PMKResolver resolve;
    AnyPromise* unresolvedPromise = [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull aResolve) {
        resolve = aResolve;
    }];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:unresolvedPromise]];

    [given([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self expectFetcherToFinishWithError:nil];

    [self.savedArticlesFetcher setSavedPageList:self.savedPageList];

    [self.savedPageList removeEntryWithListIndex:firstTitle];

    WaitForExpectations();

    [MKTVerify(self.mockArticleFetcher) cancelFetchForPageTitle:firstTitle];

    // resolve promise after the test to prevent PromiseKit warning
    resolve([NSError cancelledError]);

    assertThat(self.downloadedArticles, is(@[secondArticle]));
    assertThat(self.downloadErrors, isEmpty());
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
        MWKTitle* title          = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/Foo_%lu", e]]];
        MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
        [self.savedPageList addEntry:entry];
    }
    PMKHang([self.savedPageList save]);
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

- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
               didFetchTitle:(MWKTitle*)title
                     article:(MWKArticle*)article
                    progress:(CGFloat)progress
                       error:(NSError*)error {
    XCTAssertTrue([NSThread isMainThread]);
    if (error) {
        self.downloadErrors[title] = error;
    } else {
        XCTAssertNotNil(article);
        [self.downloadedArticles addObject:article];
    }
    NSArray* uncachedEntries = [self.savedPageList.entries bk_reject:^BOOL (MWKSavedPageEntry* entry) {
        MWKArticle* existingArticle = [self.savedPageList.dataStore articleFromDiskWithTitle:entry.title];
        return [existingArticle isCached];
    }];
    float expectedProgress = (float)(self.downloadedArticles.count + self.downloadErrors.count) / uncachedEntries.count;
    XCTAssertEqual(progress, expectedProgress);
}

- (void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError*)error {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNotNil(self.expectedFetchFinishedError, @"Wasn't expecting a fetchFinished callback!");
    self.expectedFetchFinishedError(error);
    self.expectedFetchFinishedError = nil;
}

@end
