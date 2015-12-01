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
    self.downloadErrors             = [NSMutableDictionary new];
    self.downloadedArticles         = [NSMutableArray new];
    self.expectedFetchFinishedError = nil;
    self.tempDataStore              = [MWKDataStore temporaryDataStore];
    self.mockArticleFetcher         = MKTMock([WMFArticleFetcher class]);
    self.mockImageController        = MKTMock([WMFImageController class]);
    self.savedArticlesFetcher       =
        [[SavedArticlesFetcher alloc]
         initWithSavedPageList:self.savedPageList
                articleFetcher:self.mockArticleFetcher
               imageController:self.mockImageController];
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

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    MWKArticle* stubbedArticle =
        [[MWKArticle alloc]
         initWithTitle:dummyTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    [self verifyImageDownloadAttemptForArticle:stubbedArticle];
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

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:uncachedEntryTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    [self verifyImageDownloadAttemptForArticle:stubbedArticle];
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


    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:firstArticle]];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    [self verifyImageDownloadAttemptForArticle:firstArticle];
    [self verifyImageDownloadAttemptForArticle:secondArticle];
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


    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    WaitForExpectations();

    [self verifyImageDownloadAttemptForArticle:secondArticle];
    assertThat(self.downloadedArticles, is(@[secondArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

#pragma mark - Error Handling

- (void)testReportDownloadErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    MWKTitle* dummyTitle = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:downloadError];

    WaitForExpectations();

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURLInBackground:anything()];
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

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:secondArticle]];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:downloadError];

    WaitForExpectations();

    [self verifyImageDownloadAttemptForArticle:secondArticle];
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

    __block PMKResolver resolveFirstArticleRequest;
    AnyPromise* unresolvedSecondArticlePromise = [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        resolveFirstArticleRequest = resolve;
    }];



    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:unresolvedSecondArticlePromise]];

    __block PMKResolver resolveSecondArticleRequest;
    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:secondTitle progress:anything()])
     willReturn:[AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        resolveSecondArticleRequest = resolve;
    }]];

    [self expectFetcherToFinishWithError:nil];

    /*
       !!!: Lots of dispatching here to ensure deterministic behavior, making it possible to consistently predict what
       the progress value should be.  If this were omitted, the cancellation could happen at any time, meaning the saved
       page list could have 1 or 2 entries when we get our delegate callback, resulting in flaky tests.
     */

    // start requesting first & second article
    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    // after that happens...
    dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
        // cancel the first request by removing the entry
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.savedPageList removeEntryWithListIndex:firstTitle];
        });
        dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
            // after cancellation happens, resolve the second article request, triggering delegate callback
            resolveSecondArticleRequest(secondArticle);
        });
    });

    WaitForExpectations();

    [MKTVerify(self.mockArticleFetcher) cancelFetchForPageTitle:firstTitle];

    // resolve promise after the test to prevent PromiseKit warning
    resolveFirstArticleRequest([NSError cancelledError]);

    [self verifyImageDownloadAttemptForArticle:secondArticle];
    assertThat(self.downloadedArticles, is(@[secondArticle]));
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testCancelsImageFetchesForDeletedArticles {
    [self stubListWithEntries:1];

    MWKTitle* firstTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* firstArticle =
        [[MWKArticle alloc]
         initWithTitle:firstTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:firstArticle]];

    [self expectFetcherToFinishWithError:nil];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    WaitForExpectations();

    /*
       HAX: we need to save the article on behalf of the article fetcher in order for the savedArticlesFetcher to
          get the list of image fetches to cancel from its dataStore
     */
    [firstArticle save];

    // download finished, images have now started downloading
    [self verifyImageDownloadAttemptForArticle:firstArticle];
    assertThat(self.downloadedArticles, is(@[firstArticle]));
    assertThat(self.downloadErrors, isEmpty());

    [self.savedPageList removeEntryWithListIndex:firstTitle];

    XCTestExpectation* asyncFetcherWorkExpectation =
        [self expectationWithDescription:@"Fetcher should cancel requests on its internal queue."];

    dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
        // it will try to cancel the article fetch even though it's already downloaded (no effect)
        [MKTVerify(self.mockArticleFetcher) cancelFetchForPageTitle:firstTitle];
        // then it will cancel any download for its images
        [firstArticle.allImageURLs bk_each:^(NSURL* imageURL) {
            [MKTVerify(self.mockImageController) cancelFetchForURL:imageURL];
        }];
        [asyncFetcherWorkExpectation fulfill];
    });

    WaitForExpectations();
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

- (void)verifyImageDownloadAttemptForArticle:(MWKArticle*)article {
    [[article allImageURLs] bk_each:^(NSURL* imageURL) {
        [MKTVerify(self.mockImageController) fetchImageWithURLInBackground:imageURL];
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
