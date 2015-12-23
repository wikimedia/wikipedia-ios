//
//  SavedArticlesFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SavedArticlesFetcherTests.h"
#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"
#import "MWKArticle+HTMLImageImport.h"

@implementation SavedArticlesFetcherTests

- (void)setUp {
    [super setUp];
    self.downloadErrors             = [NSMutableDictionary new];
    self.downloadedArticles         = [NSMutableArray new];
    self.expectedFetchFinishedError = nil;
    self.tempDataStore              = [MWKDataStore temporaryDataStore];
    self.mockArticleFetcher         = MKTMock([WMFArticleFetcher class]);
    self.mockImageController        = MKTMock([WMFImageController class]);
    self.mockImageInfoFetcher       = MKTMock([MWKImageInfoFetcher class]);
    self.savedArticlesFetcher       =
        [[SavedArticlesFetcher alloc]
         initWithSavedPageList:self.savedPageList
                articleFetcher:self.mockArticleFetcher
               imageController:self.mockImageController
              imageInfoFetcher:self.mockImageInfoFetcher];
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

    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForTitle:[MWKTitle random] fixtureName:@"Obama"];

    [self.savedPageList addSavedPageWithTitle:stubbedArticle.title];

    [self expectFetcherToFinishWithError:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
    [self verifyPersistedImageInfoForArticle:stubbedArticle];
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testStartDownloadingUncachedArticleAlreadyInList {
    [self stubListWithEntries:1];

    MWKTitle* uncachedEntryTitle = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];

    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForTitle:uncachedEntryTitle fixtureName:@"Obama"];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
    [self verifyPersistedImageInfoForArticle:stubbedArticle];
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testCorrectProgressForMultipleSuccessfulDownloads {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* firstArticle = [self stubAllSuccessfulResponsesForTitle:firstTitle fixtureName:@"Obama"];

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle = [self stubAllSuccessfulResponsesForTitle:secondTitle fixtureName:@"Exoplanet.mobileview"];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];


    assertThat(self.downloadedArticles, is(@[firstArticle, secondArticle]));
    [self verifyPersistedImageInfoForArticle:firstArticle];
    [self verifyPersistedImageInfoForArticle:secondArticle];
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testSkipsCachedArticles {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle      = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* cachedArticle =
        [[MWKArticle alloc]
         initWithTitle:firstTitle
             dataStore:self.tempDataStore
                  dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];
    [cachedArticle importAndSaveImagesFromSectionHTML];
    [cachedArticle save];
    NSAssert(cachedArticle.isCached, @"Test depends on article being considered cached after save!");

    MWKTitle* secondTitle       = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* uncachedArticle = [self stubAllSuccessfulResponsesForTitle:secondTitle fixtureName:@"Exoplanet.mobileview"];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    // should not have fetched anything for cached article
    [MKTVerifyCount(self.mockArticleFetcher, MKTNever()) fetchArticleForPageTitle:cachedArticle.title progress:anything()];

    // should have fetched article & image data for second, uncached article
    assertThat(self.downloadedArticles, is(@[uncachedArticle]));
    [self verifyPersistedImageInfoForArticle:uncachedArticle];
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

    [self waitForExpectationsWithTimeout:2 handler:nil];

    [MKTVerifyCount(self.mockImageController, MKTNever()) fetchImageWithURLInBackground:anything()];
    assertThat(self.downloadedArticles, isEmpty());
    assertThat(self.downloadErrors, is(@{dummyTitle: downloadError}));
}

- (void)testReportArticleImageErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    MWKTitle* dummyTitle       = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];
    MWKArticle* stubbedArticle = [self stubArticleResponsesForTitle:dummyTitle fixtureName:@"Obama"];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [stubbedArticle.allImageURLs bk_each:^(NSURL* imageURL) {
        [MKTGiven([self.mockImageController fetchImageWithURLInBackground:imageURL])
         willReturn:[AnyPromise promiseWithValue:downloadError]];
    }];

    // Need to stub gallery responses to prevent NSNull errors
    [self stubGalleryResponsesForArticle:stubbedArticle];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, isEmpty());
    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
}

- (void)testReportGalleryInfoErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    MWKTitle* dummyTitle       = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];
    MWKArticle* stubbedArticle = [self stubArticleResponsesForTitle:dummyTitle fixtureName:@"Obama"];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self stubArticleImageResponsesForArticle:stubbedArticle];

    [stubbedArticle.images.uniqueLargestVariants bk_each:^(MWKImage* image) {
        NSString* canonicalPageTitle = [@"File:" stringByAppendingString:image.canonicalFilename];
        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:canonicalPageTitle fromSite:stubbedArticle.title.site])
         willReturn:[AnyPromise promiseWithValue:downloadError]];
    }];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, isEmpty());
    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
}

- (void)testReportGalleryImageErrors {
    [self stubListWithEntries:0];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    MWKTitle* dummyTitle       = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"]];
    MWKArticle* stubbedArticle = [self stubArticleResponsesForTitle:dummyTitle fixtureName:@"Obama"];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:dummyTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];

    [self stubArticleImageResponsesForArticle:stubbedArticle];

    [stubbedArticle.images.uniqueLargestVariants bk_each:^(MWKImage* image) {
        MWKImageInfo* stubbedImageInfo = [self imageInfoStubForImage:image];
        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:stubbedImageInfo.canonicalPageTitle
                                                             fromSite:stubbedArticle.title.site])
         willReturn:[AnyPromise promiseWithValue:stubbedImageInfo]];

        [MKTGiven([self.mockImageController fetchImageWithURLInBackground:stubbedImageInfo.imageThumbURL])
         willReturn:[AnyPromise promiseWithValue:downloadError]];
    }];

    [self.savedPageList addSavedPageWithTitle:dummyTitle];

    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, isEmpty());
    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
}

- (void)testContinuesDownloadingIfArticleDownloadFails {
    [self stubListWithEntries:2];

    MWKTitle* firstTitle = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];

    MWKTitle* secondTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries[1] title];
    MWKArticle* secondArticle = [self stubAllSuccessfulResponsesForTitle:secondTitle fixtureName:@"Exoplanet.mobileview"];

    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:firstTitle progress:anything()])
     willReturn:[AnyPromise promiseWithValue:downloadError]];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self expectFetcherToFinishWithError:downloadError];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    assertThat(self.downloadedArticles, is(@[secondArticle]));
    [self verifyPersistedImageInfoForArticle:secondArticle];
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

    [self stubImageResponsesForArticle:secondArticle];

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

    [self waitForExpectationsWithTimeout:2 handler:nil];

    [MKTVerify(self.mockArticleFetcher) cancelFetchForPageTitle:firstTitle];

    // resolve promise after the test to prevent PromiseKit warning
    resolveFirstArticleRequest([NSError cancelledError]);

    assertThat(self.downloadedArticles, is(@[secondArticle]));
    [self verifyPersistedImageInfoForArticle:secondArticle];
    assertThat(self.downloadErrors, isEmpty());
}

- (void)testCancelsImageFetchesForDeletedArticles {
    [self stubListWithEntries:1];

    MWKTitle* firstTitle     = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject title];
    MWKArticle* firstArticle = [self stubAllSuccessfulResponsesForTitle:firstTitle fixtureName:@"Exoplanet.mobileview"];

    [self expectFetcherToFinishWithError:nil];

    [self.savedArticlesFetcher fetchAndObserveSavedPageList];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    /*
       HAX: we need to save the article on behalf of the article fetcher in order for the savedArticlesFetcher to
          get the list of image fetches to cancel from its dataStore
     */
    [firstArticle save];

    // download finished, images have now started downloading
    assertThat(self.downloadedArticles, is(@[firstArticle]));
    [self verifyPersistedImageInfoForArticle:firstArticle];
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

    [self waitForExpectationsWithTimeout:2 handler:nil];
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

- (void)verifyPersistedImageInfoForArticle:(MWKArticle*)article {
    NSArray<NSString*>* expectedCanonicalPageTitles = [MWKImage mapFilenamesFromImages:article.images.uniqueLargestVariants];
    NSArray* persistedImageInfoCanonicalPageTitles  =
        [[self.tempDataStore imageInfoForTitle:article.title]
         valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, canonicalPageTitle)];
    assertThat(persistedImageInfoCanonicalPageTitles, containsItemsInCollectionInAnyOrder(expectedCanonicalPageTitles));
}

- (MWKArticle*)stubAllSuccessfulResponsesForTitle:(MWKTitle*)title fixtureName:(NSString*)fixtureName {
    MWKArticle* article = [self stubArticleResponsesForTitle:title fixtureName:fixtureName];
    [self stubImageResponsesForArticle:article];
    return article;
}

- (MWKArticle*)stubArticleResponsesForTitle:(MWKTitle*)title fixtureName:(NSString*)fixtureName {
    id json             = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"mobileview"];
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:title
                                                  dataStore:self.tempDataStore
                                                       dict:json];
    // make sure article's image list is populated. shouldn't matter that image metadata is saved as long as the article
    // itself is not. saving article data could interfere with the tests (since that would make it cached)
    [article importAndSaveImagesFromSectionHTML];
    NSParameterAssert([article.images count] > 1);
    NSParameterAssert(article.images.uniqueLargestVariants.count > 1);
    [MKTGiven([self.mockArticleFetcher fetchArticleForPageTitle:article.title progress:anything()])
     willReturn:[AnyPromise promiseWithValue:article]];
    return article;
}

- (MWKImageInfo*)imageInfoStubForImage:(MWKImage*)image {
    return
        [[MWKImageInfo alloc]
         initWithCanonicalPageTitle:[@"File:" stringByAppendingString:image.canonicalFilename]
                   canonicalFileURL:[NSURL URLWithString:@"https://dummy.org/foo"]
                   imageDescription:nil
                            license:nil
                        filePageURL:nil
                      imageThumbURL:[NSURL URLWithString:[image.sourceURLString stringByAppendingString:@"/galleryDummy.jpg"]]
                              owner:nil
                          imageSize:CGSizeZero
                          thumbSize:CGSizeZero];
}

- (void)stubImageResponsesForArticle:(MWKArticle*)article {
    [self stubArticleImageResponsesForArticle:article];
    [self stubGalleryResponsesForArticle:article];
}

- (void)stubArticleImageResponsesForArticle:(MWKArticle*)article {
    [[article allImageURLs] bk_each:^(NSURL* imageURL) {
        [MKTGiven([self.mockImageController fetchImageWithURLInBackground:imageURL])
         willReturn:[AnyPromise promiseWithValue:[NSData data]]];
    }];
}

- (void)stubGalleryResponsesForArticle:(MWKArticle*)article {
    [article.images.uniqueLargestVariants bk_each:^(MWKImage* image) {
        MWKImageInfo* stubbedImageInfo = [self imageInfoStubForImage:image];

        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:stubbedImageInfo.canonicalPageTitle
                                                             fromSite:article.title.site])
         willReturn:[AnyPromise promiseWithValue:stubbedImageInfo]];

        [MKTGiven([self.mockImageController fetchImageWithURLInBackground:stubbedImageInfo.imageThumbURL])
         willReturn:[AnyPromise promiseWithValue:[NSData data]]];
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
