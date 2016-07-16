//#import "SavedArticlesFetcherTests.h"
//#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"
//#import "WMFURLCache.h"
//#import <OCMockito/NSInvocation+OCMockito.h>
//
//@implementation SavedArticlesFetcherTests
//
//- (void)setUp {
//    [super setUp];
//    WMFURLCache* urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
//                                                           diskCapacity:MegabytesToBytes(128)
//                                                               diskPath:nil];
//    [NSURLCache setSharedURLCache:urlCache];
//    self.downloadErrors             = [NSMutableDictionary new];
//    self.downloadedArticles         = [NSMutableArray new];
//    self.expectedFetchFinishedError = nil;
//    self.tempDataStore              = [MWKDataStore temporaryDataStore];
//    self.mockArticleFetcher         = MKTMock([WMFArticleFetcher class]);
//    self.mockImageController        = MKTMock([WMFImageController class]);
//    self.mockImageInfoFetcher       = MKTMock([MWKImageInfoFetcher class]);
//    self.savedArticlesFetcher       =
//        [[SavedArticlesFetcher alloc]
//         initWithSavedPageList:self.savedPageList
//                articleFetcher:self.mockArticleFetcher
//               imageController:self.mockImageController
//              imageInfoFetcher:self.mockImageInfoFetcher];
//    self.savedArticlesFetcher.fetchFinishedDelegate = self;
//}
//
//- (void)tearDown {
//    XCTAssertNil(self.expectedFetchFinishedError, @"fetchFinished: callback not invoked!");
//    [self.tempDataStore removeFolderAtBasePath];
//    [super tearDown];
//}
//
//+ (NSArray<NSInvocation*>*)testInvocations {
//    return [[NSProcessInfo processInfo] wmf_isTravis] ? @[] : [super testInvocations];
//}
//
//#pragma mark - Downloading
//
//- (void)testStartDownloadingArticleWhenAddedToList {
//    [self stubListWithEntries:0];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForArticleURL:[NSURL wmf_randomArticleURL] fixtureName:@"Obama"];
//
//    [self.savedPageList addSavedPageWithURL:stubbedArticle.url];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
//    [self verifyPersistedImageInfoForArticle:stubbedArticle];
//    assertThat(self.downloadErrors, isEmpty());
//}
//
//- (void)testStartDownloadingUncachedArticleAlreadyInList {
//    [self stubListWithEntries:1];
//
//    NSURL* uncachedEntryURL = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//
//    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForArticleURL:uncachedEntryURL fixtureName:@"Obama"];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, is(@[stubbedArticle]));
//    [self verifyPersistedImageInfoForArticle:stubbedArticle];
//    assertThat(self.downloadErrors, isEmpty());
//}
//
//- (void)testCorrectProgressForMultipleSuccessfulDownloads {
//    [self stubListWithEntries:2];
//
//    NSURL* firstURL          = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//    MWKArticle* firstArticle = [self stubAllSuccessfulResponsesForArticleURL:firstURL fixtureName:@"Obama"];
//
//    NSURL* secondURL          = [(MWKSavedPageEntry*)self.savedPageList.entries[1] url];
//    MWKArticle* secondArticle = [self stubAllSuccessfulResponsesForArticleURL:secondURL fixtureName:@"Exoplanet.mobileview"];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//
//    assertThat(self.downloadedArticles, is(@[firstArticle, secondArticle]));
//    [self verifyPersistedImageInfoForArticle:firstArticle];
//    [self verifyPersistedImageInfoForArticle:secondArticle];
//    assertThat(self.downloadErrors, isEmpty());
//}
//
//- (void)testSkipsCachedArticles {
//    [self stubListWithEntries:2];
//
//    NSURL* firstURL           = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//    MWKArticle* cachedArticle =
//        [[MWKArticle alloc]
//         initWithURL:firstURL
//           dataStore:self.tempDataStore
//                dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];
//    [cachedArticle save];
//    NSAssert(cachedArticle.isCached, @"Test depends on article being considered cached after save!");
//
//    NSURL* secondURL            = [(MWKSavedPageEntry*)self.savedPageList.entries[1] url];
//    MWKArticle* uncachedArticle = [self stubAllSuccessfulResponsesForArticleURL:secondURL fixtureName:@"Exoplanet.mobileview"];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    // should not have fetched anything for cached article
//    [MKTVerifyCount(self.mockArticleFetcher, MKTNever()) fetchArticleForURL:cachedArticle.url progress:anything()];
//
//    // should have fetched article & image data for second, uncached article
//    assertThat(self.downloadedArticles, is(@[uncachedArticle]));
//    [self verifyPersistedImageInfoForArticle:uncachedArticle];
//    assertThat(self.downloadErrors, isEmpty());
//}
//
//#pragma mark - Error Handling
//
//- (void)testReportDownloadErrors {
//    [self stubListWithEntries:0];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    NSURL* dummyURL = [NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"];
//
//    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:dummyURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:downloadError]];
//
//    [self.savedPageList addSavedPageWithURL:dummyURL];
//
//    [self expectFetcherToFinishWithError:downloadError];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    [MKTVerifyCount(self.mockImageController, MKTNever()) cacheImageWithURLInBackground:anything() failure:anything() success:anything()];
//    assertThat(self.downloadedArticles, isEmpty());
//    assertThat(self.downloadErrors, is(@{dummyURL: downloadError}));
//}
//
//- (void)testReportArticleImageErrors {
//    [self stubListWithEntries:0];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    NSURL* dummyURL            = [NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"];
//    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForArticleURL:dummyURL fixtureName:@"Obama"];
//
//    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:dummyURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];
//
//    [stubbedArticle.allImageURLs bk_each:^(NSURL* imageURL) {
//        [MKTGiven([self.mockImageController cacheImageWithURLInBackground:imageURL failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//            NSArray* args = [invocation mkt_arguments];
//            WMFErrorHandler failure = args[1];
//            failure(downloadError);
//            return nil;
//        }];
//    }];
//
//    [self stubMultipleImageCacheFailureWithError:downloadError];
//
//    // Need to stub gallery responses to prevent NSNull errors
//    [self stubGalleryResponsesForArticle:stubbedArticle];
//
//    [self.savedPageList addSavedPageWithURL:dummyURL];
//
//    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, isEmpty());
//    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
//}
//
//- (void)testReportGalleryInfoErrors {
//    [self stubListWithEntries:0];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    NSURL* dummyURL            = [NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"];
//    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForArticleURL:dummyURL fixtureName:@"Obama"];
//
//    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:dummyURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];
//
//    [self stubArticleImageResponsesForArticle:stubbedArticle];
//
//    [[stubbedArticle imagesForGallery] bk_each:^(MWKImage* image) {
//        NSString* canonicalPageTitle = [@"File:" stringByAppendingString:image.canonicalFilename];
//        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:canonicalPageTitle fromDomainURL:stubbedArticle.url.wmf_domainURL])
//         willReturn:[AnyPromise promiseWithValue:downloadError]];
//    }];
//
//    [self stubMultipleImageCacheFailureWithError:downloadError];
//
//    [self.savedPageList addSavedPageWithURL:dummyURL];
//
//    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, isEmpty());
//    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
//}
//
//- (void)testReportGalleryImageErrors {
//    [self stubListWithEntries:0];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    NSURL* dummyURL            = [NSURL URLWithString:@"https://en.wikikpedia.org/wiki/Foo"];
//    MWKArticle* stubbedArticle = [self stubAllSuccessfulResponsesForArticleURL:dummyURL fixtureName:@"Obama"];
//
//    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:dummyURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:stubbedArticle]];
//
//    [self stubArticleImageResponsesForArticle:stubbedArticle];
//
//    [[stubbedArticle imagesForGallery] bk_each:^(MWKImage* image) {
//        MWKImageInfo* stubbedImageInfo = [self imageInfoStubForImage:image];
//        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:stubbedImageInfo.canonicalPageTitle
//                                                        fromDomainURL:stubbedArticle.url.wmf_domainURL])
//         willReturn:[AnyPromise promiseWithValue:stubbedImageInfo]];
//
//        [MKTGiven([self.mockImageController cacheImageWithURLInBackground:stubbedImageInfo.imageThumbURL failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//            NSArray* args = [invocation mkt_arguments];
//            WMFErrorHandler failure = args[1];
//            if (![failure isKindOfClass:[HCIsAnything class]]) {
//                failure(downloadError);
//            }
//            return nil;
//        }];
//    }];
//
//    [self stubMultipleImageCacheFailureWithError:downloadError];
//
//    [self.savedPageList addSavedPageWithURL:dummyURL];
//
//    [self expectFetcherToFinishWithError:[NSError wmf_savedPageImageDownloadError]];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, isEmpty());
//    assertThat(self.downloadErrors, hasValue([NSError wmf_savedPageImageDownloadError]));
//}
//
//- (void)testContinuesDownloadingIfArticleDownloadFails {
//    [self stubListWithEntries:2];
//
//    NSURL* firstURL = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//
//    NSURL* secondURL          = [(MWKSavedPageEntry*)self.savedPageList.entries[1] url];
//    MWKArticle* secondArticle = [self stubAllSuccessfulResponsesForArticleURL:secondURL fixtureName:@"Exoplanet.mobileview"];
//
//    NSError* downloadError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:firstURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:downloadError]];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    [self expectFetcherToFinishWithError:downloadError];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    assertThat(self.downloadedArticles, is(@[secondArticle]));
//    [self verifyPersistedImageInfoForArticle:secondArticle];
//    assertThat(self.downloadErrors, is(@{firstURL: downloadError}));
//}
//
//#pragma mark - Cancellation
//
//- (void)testStopDownloadingAnArticleWhenItIsDeleted {
//    [self stubListWithEntries:2];
//
//    NSURL* firstURL = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//
//    NSURL* secondURL          = [(MWKSavedPageEntry*)self.savedPageList.entries[1] url];
//    MWKArticle* secondArticle =
//        [[MWKArticle alloc]
//         initWithURL:secondURL
//           dataStore:self.tempDataStore
//                dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Exoplanet.mobileview"][@"mobileview"]];
//
//    __block PMKResolver resolveFirstArticleRequest;
//    AnyPromise* unresolvedSecondArticlePromise = [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
//        resolveFirstArticleRequest = resolve;
//    }];
//
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:firstURL progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:unresolvedSecondArticlePromise]];
//
//    __block PMKResolver resolveSecondArticleRequest;
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:secondURL progress:anything()])
//     willReturn:[AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
//        resolveSecondArticleRequest = resolve;
//    }]];
//
//    [self stubImageResponsesForArticle:secondArticle];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    /*
//       !!!: Lots of dispatching here to ensure deterministic behavior, making it possible to consistently predict what
//       the progress value should be.  If this were omitted, the cancellation could happen at any time, meaning the saved
//       page list could have 1 or 2 entries when we get our delegate callback, resulting in flaky tests.
//     */
//
//    // start requesting first & second article
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    // after that happens...
//    dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
//        // cancel the first request by removing the entry
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self.savedPageList removeEntryWithListIndex:firstURL];
//        });
//        dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
//            // after cancellation happens, resolve the second article request, triggering delegate callback
//            resolveSecondArticleRequest(secondArticle);
//        });
//    });
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    [MKTVerify(self.mockArticleFetcher) cancelFetchForURL:firstURL];
//
//    // resolve promise after the test to prevent PromiseKit warning
//    resolveFirstArticleRequest([NSError cancelledError]);
//
//    assertThat(self.downloadedArticles, is(@[secondArticle]));
//    [self verifyPersistedImageInfoForArticle:secondArticle];
//    assertThat(self.downloadErrors, isEmpty());
//}
//
//- (void)testCancelsImageFetchesForDeletedArticles {
//    [self stubListWithEntries:1];
//
//    NSURL* firstURL          = [(MWKSavedPageEntry*)self.savedPageList.entries.firstObject url];
//    MWKArticle* firstArticle = [self stubAllSuccessfulResponsesForArticleURL:firstURL fixtureName:@"Exoplanet.mobileview"];
//
//    [self expectFetcherToFinishWithError:nil];
//
//    [self.savedArticlesFetcher fetchAndObserveSavedPageList];
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//
//    /*
//       HAX: we need to save the article on behalf of the article fetcher in order for the savedArticlesFetcher to
//          get the list of image fetches to cancel from its dataStore
//     */
//    [firstArticle save];
//
//    // download finished, images have now started downloading
//    assertThat(self.downloadedArticles, is(@[firstArticle]));
//    [self verifyPersistedImageInfoForArticle:firstArticle];
//    assertThat(self.downloadErrors, isEmpty());
//
//    [self.savedPageList removeEntryWithListIndex:firstURL];
//
//    XCTestExpectation* asyncFetcherWorkExpectation =
//        [self expectationWithDescription:@"Fetcher should cancel requests on its internal queue."];
//
//    dispatch_async(self.savedArticlesFetcher.accessQueue, ^{
//        // it will try to cancel the article fetch even though it's already downloaded (no effect)
//        [MKTVerify(self.mockArticleFetcher) cancelFetchForURL:firstURL];
//        // then it will cancel any download for its images
//        [firstArticle.imageURLsForSaving bk_each:^(NSURL* imageURL) {
//            [MKTVerify(self.mockImageController) cancelFetchForURL:imageURL];
//        }];
//        [asyncFetcherWorkExpectation fulfill];
//    });
//
//    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout*2 handler:nil];
//}
//
//#pragma mark - Utils
//
//- (MWKSavedPageList*)savedPageList {
//    if (!_savedPageList) {
//        self.savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self.tempDataStore];
//    }
//    return _savedPageList;
//}
//
//- (void)stubListWithEntries:(NSUInteger)numEntries {
//    for (NSUInteger e = 0; e < numEntries; e++) {
//        NSURL* url               = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/Foo_%lu", e]];
//        MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithURL:url];
//        [self.savedPageList addEntry:entry];
//    }
//    PMKHang([self.savedPageList save]);
//}
//
//- (void)verifyPersistedImageInfoForArticle:(MWKArticle*)article {
//    NSArray<NSString*>* expectedCanonicalPageTitles = [MWKImage mapFilenamesFromImages:[article imagesForGallery]];
//    NSArray* persistedImageInfoCanonicalPageTitles  =
//        [[self.tempDataStore imageInfoForArticleWithURL:article.url]
//         valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, canonicalPageTitle)];
//    assertThat(persistedImageInfoCanonicalPageTitles, containsItemsInCollectionInAnyOrder(expectedCanonicalPageTitles));
//}
//
//- (MWKArticle*)stubAllSuccessfulResponsesForArticleURL:(NSURL*)articleURL fixtureName:(NSString*)fixtureName {
//    MWKArticle* article = [self stubArticleResponsesForArticleURL:articleURL fixtureName:fixtureName];
//    [self stubImageResponsesForArticle:article];
//    return article;
//}
//
//- (MWKArticle*)stubArticleResponsesForArticleURL:(NSURL*)articleURL fixtureName:(NSString*)fixtureName {
//    id json             = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"mobileview"];
//    MWKArticle* article = [[MWKArticle alloc] initWithURL:articleURL
//                                                dataStore:self.tempDataStore
//                                                     dict:json];
//    [MKTGiven([self.mockArticleFetcher fetchArticleForURL:article.url progress:anything()])
//     willReturn:[AnyPromise promiseWithValue:article]];
//    return article;
//}
//
//- (void)stubMultipleImageCacheFailureWithError:(NSError*)error {
//    [MKTGiven([self.mockImageController cacheImagesWithURLsInBackground:anything() failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//        NSArray* args = [invocation mkt_arguments];
//        WMFErrorHandler failure = args[1];
//        if (![failure isKindOfClass:[HCIsAnything class]]) {
//            failure(error);
//        }
//        return nil;
//    }];
//}
//
//- (MWKImageInfo*)imageInfoStubForImage:(MWKImage*)image {
//    return
//        [[MWKImageInfo alloc]
//         initWithCanonicalPageTitle:[@"File:" stringByAppendingString:image.canonicalFilename]
//                   canonicalFileURL:[NSURL URLWithString:@"https://dummy.org/foo"]
//                   imageDescription:nil
//                            license:nil
//                        filePageURL:nil
//                      imageThumbURL:[NSURL URLWithString:[image.sourceURLString stringByAppendingString:@"/galleryDummy.jpg"]]
//                              owner:nil
//                          imageSize:CGSizeZero
//                          thumbSize:CGSizeZero];
//}
//
//- (void)stubImageResponsesForArticle:(MWKArticle*)article {
//    [self stubArticleImageResponsesForArticle:article];
//    [self stubGalleryResponsesForArticle:article];
//}
//
//- (void)stubArticleImageResponsesForArticle:(MWKArticle*)article {
//    [[article imageURLsForSaving] bk_each:^(NSURL* imageURL) {
//        [MKTGiven([self.mockImageController cacheImageWithURLInBackground:imageURL failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//            NSArray* args = [invocation mkt_arguments];
//            WMFSuccessBoolHandler success = args[2];
//            if (![success isKindOfClass:[HCIsAnything class]]) {
//                success(YES);
//            }
//            return nil;
//        }];
//    }];
//
//    [MKTGiven([self.mockImageController cacheImagesWithURLsInBackground:anything() failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//        NSArray* args = [invocation mkt_arguments];
//        WMFSuccessBoolHandler success = args[2];
//        if (![success isKindOfClass:[HCIsAnything class]]) {
//            success(YES);
//        }
//        return nil;
//    }];
//}
//
//- (void)stubGalleryResponsesForArticle:(MWKArticle*)article {
//    [[article imagesForGallery] bk_each:^(MWKImage* image) {
//        MWKImageInfo* stubbedImageInfo = [self imageInfoStubForImage:image];
//
//        [MKTGiven([self.mockImageInfoFetcher fetchGalleryInfoForImage:stubbedImageInfo.canonicalPageTitle
//                                                        fromDomainURL:article.url.wmf_domainURL])
//         willReturn:[AnyPromise promiseWithValue:stubbedImageInfo]];
//
//        [MKTGiven([self.mockImageController cacheImageWithURLInBackground:stubbedImageInfo.imageThumbURL failure:anything() success:anything()]) willDo:^id (NSInvocation* invocation){
//            NSArray* args = [invocation mkt_arguments];
//            WMFSuccessBoolHandler success = args[2];
//            success(YES);
//            return @"";
//        }];
//    }];
//}
//
//- (void)expectFetcherToFinishWithError:(NSError*)error {
//    XCTestExpectation* fetchFinishedExpectation = [self expectationWithDescription:@"fetch finished"];
//    @weakify(self);
//    self.expectedFetchFinishedError = ^(NSError* e) {
//        @strongify(self);
//        XCTAssertEqualObjects(e, error);
//        [fetchFinishedExpectation fulfill];
//    };
//}
//
//#pragma mark - SavedArticlesFetcherDelegate
//
//- (void)savedArticlesFetcher:(SavedArticlesFetcher*)savedArticlesFetcher
//                 didFetchURL:(NSURL*)url
//                     article:(MWKArticle*)article
//                    progress:(CGFloat)progress
//                       error:(NSError*)error {
//    XCTAssertTrue([NSThread isMainThread]);
//    if (error) {
//        self.downloadErrors[url] = error;
//    } else {
//        XCTAssertNotNil(article);
//        [self.downloadedArticles addObject:article];
//    }
//    NSArray* uncachedEntries = [self.savedPageList.entries bk_reject:^BOOL (MWKSavedPageEntry* entry) {
//        MWKArticle* existingArticle = [self.savedPageList.dataStore articleFromDiskWithURL:entry.url];
//        return [existingArticle isCached];
//    }];
//    float expectedProgress = (float)(self.downloadedArticles.count + self.downloadErrors.count) / uncachedEntries.count;
//    XCTAssertEqual(progress, expectedProgress);
//}
//
//- (void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError*)error {
//    XCTAssertTrue([NSThread isMainThread]);
//    XCTAssertNotNil(self.expectedFetchFinishedError, @"Wasn't expecting a fetchFinished callback!");
//    self.expectedFetchFinishedError(error);
//    self.expectedFetchFinishedError = nil;
//}
//
//@end
