#define HC_SHORTHAND 1
#define MOCKITO_SHORTHAND 1

#import <UIKit/UIKit.h>
#import <BlocksKit/BlocksKit.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

#import "MWKImage+AssociationTestUtils.h"
#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"
#import "WMFAsyncTestCase.h"
#import "WMFImageInfoController_Private.h"
#import "MWKImage.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "NSArray+WMFShuffle.h"
#import "WMFRangeUtils.h"

static NSValue *WMFBoxedRangeMake(NSUInteger loc, NSUInteger len) {
  return [NSValue valueWithRange:NSMakeRange(loc, len)];
}

@interface WMFImageInfoControllerTests : WMFAsyncTestCase <WMFImageInfoControllerDelegate>
@property WMFImageInfoController *controller;
@property MWKArticle *testArticle;
@property MWKImageInfoFetcher *mockInfoFetcher;
@property id<WMFImageInfoControllerDelegate> mockDelegate;
@property MWKDataStore *tmpDataStore;
@end

@implementation WMFImageInfoControllerTests

- (void)setUp {
  [super setUp];

  self.mockInfoFetcher = MKTMock([MWKImageInfoFetcher class]);
  self.tmpDataStore = [MWKDataStore temporaryDataStore];
  self.mockDelegate = MKTMockProtocol(@protocol(WMFImageInfoControllerDelegate));

  NSURL *testTitle = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"]
      wmf_URLWithTitle:@"foo"];

  self.testArticle = [[MWKArticle alloc] initWithURL:testTitle dataStore:self.tmpDataStore];

  NSArray<MWKImage *> *testImages = [[self generateSourceURLs:10] bk_map:^MWKImage *(NSString *urlString) {
    return [[MWKImage alloc] initWithArticle:self.testArticle sourceURLString:urlString];
  }];

  self.controller = [[WMFImageInfoController alloc] initWithDataStore:self.tmpDataStore
                                                            batchSize:2
                                                          infoFetcher:self.mockInfoFetcher];

  [self.controller setUniqueArticleImages:testImages forArticleURL:self.testArticle.url];

  self.controller.delegate = self;
}

- (void)tearDown {
  [self.tmpDataStore removeFolderAtBasePath];
  [super tearDown];
}

#pragma mark - Tests

- (void)testReadsFromDataStoreLazilyAndPopulatesFetchedIndices {
  MWKDataStore *mockDataStore = MKTMock([MWKDataStore class]);

  NSURL *testURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale]
      wmf_URLWithTitle:@"foo"];

  MWKArticle *dummyArticle = [[MWKArticle alloc] initWithURL:testURL dataStore:mockDataStore];

  NSArray *testImages = [[self generateSourceURLs:5] bk_map:^MWKImage *(NSString *sourceURL) {
    return [[MWKImage alloc] initWithArticle:dummyArticle sourceURLString:sourceURL];
  }];
  NSRange preFetchedRange = NSMakeRange(0, 2);
  NSArray *expectedImageInfo = [[MWKImageInfo mappedFromImages:testImages] subarrayWithRange:preFetchedRange];

  [MKTGiven([mockDataStore imageInfoForArticleWithURL:testURL]) willReturn:expectedImageInfo];

  WMFImageInfoController *controller = [[WMFImageInfoController alloc] initWithDataStore:mockDataStore
                                                                               batchSize:2
                                                                             infoFetcher:self.mockInfoFetcher];
  [controller setUniqueArticleImages:testImages forArticleURL:dummyArticle.url];

  assertThat(controller.indexedImageInfo.allValues, containsItemsInCollectionInAnyOrder(expectedImageInfo));
  assertThat(controller.uniqueArticleImages, is(testImages));
  assertThat(controller.fetchedIndices, is(equalTo([NSIndexSet indexSetWithIndexesInRange:preFetchedRange])));
}

- (void)testBatchRange {
  for (NSUInteger i = 0; i < 10; i++) {
    NSRange batchRange = [self.controller batchRangeForTargetIndex:i];
    assertThat(@(batchRange.length), is(equalToUnsignedInteger(self.controller.infoBatchSize)));
    assertThat(@(batchRange.location), is(lessThanOrEqualTo(@(i))));
    assertThat(@(batchRange.location + batchRange.length), is(greaterThanOrEqualTo(@(i))));
  }
}

- (void)testFetchBatchRanges {
  NSMutableIndexSet *indexesToFetch = [NSMutableIndexSet indexSetWithIndex:0];
  [indexesToFetch addIndex:self.controller.uniqueArticleImages.count - 1];
  [self.controller fetchBatchesContainingIndexes:indexesToFetch];
  [indexesToFetch enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    NSRange expectedRange = [self.controller batchRangeForTargetIndex:idx];
    assertThat(@(WMFRangeIsNotFoundOrEmpty(expectedRange)), isFalse());
    NSArray *expectedTitles = [self expectedTitlesForRange:expectedRange];
    [MKTVerifyCount(self.mockInfoFetcher, MKTTimes(1)) fetchGalleryInfoForImageFiles:expectedTitles
                                                                         fromSiteURL:self.testArticle.url.wmf_siteURL
                                                                             success:anything()
                                                                             failure:anything()];
  }];
}

- (void)testIgnoreOutOfBoundsNeighbor {
  [self.controller fetchBatchContainingIndex:0 withNthNeighbor:self.controller.uniqueArticleImages.count + 1];
  [self verifyInfoFetcherCallForIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)testFetchBatchAlongWithNeighborReturnsOneRequestForEachFetch {
  [MKTGiven([self.mockInfoFetcher
      fetchGalleryInfoForImageFiles:[self expectedTitlesForRange:[self.controller batchRangeForTargetIndex:0]]
                        fromSiteURL:anything()
                            success:anything()
                            failure:anything()]) willReturn:@"dummy request"];

  [MKTGiven([self.mockInfoFetcher
      fetchGalleryInfoForImageFiles:[self expectedTitlesForRange:[self.controller batchRangeForTargetIndex:self.controller.infoBatchSize]]
                        fromSiteURL:anything()
                            success:anything()
                            failure:anything()]) willReturn:@"dummy request 2"];

  NSArray *requests = [self.controller fetchBatchContainingIndex:0 withNthNeighbor:self.controller.infoBatchSize];
  assertThat(requests, is(@[ @"dummy request", @"dummy request 2" ]));
}

- (void)testFetchBatchAlongWithNeighborIndexesInTheSameBatchOnlyResultsInOneFetch {
  [self.controller fetchBatchContainingIndex:0 withNthNeighbor:self.controller.infoBatchSize - 1];
  [MKTVerifyCount(self.mockInfoFetcher, MKTTimes(1)) fetchGalleryInfoForImageFiles:anything()
                                                                       fromSiteURL:anything()
                                                                           success:anything()
                                                                           failure:anything()];
}

- (void)testIterativeFetchOfAllItems {
  [self verifySuccessfulFetchesForRanges:[self createAllExpectedBatches]];
}

- (void)testOutOfOrderFetchOfAllItems {
  [self verifySuccessfulFetchesForRanges:[[self createAllExpectedBatches] wmf_shuffledCopy]];
}

- (void)testFetchingItemsThatWereAlreadyFetchedHasNoEffect {
  NSArray *fetchedBatches = [self createAllExpectedBatches];

  // fetch them in order
  [self verifySuccessfulFetchesForRanges:fetchedBatches];

  // attempt to fetch them all again in any order, nothing should happen
  for (NSValue *boxedRange in [fetchedBatches wmf_shuffledCopy]) {
    NSRange range = [boxedRange rangeValue];
    [self.controller fetchBatchContainingIndex:range.location];
  }

  [MKTVerifyCount(self.mockInfoFetcher, MKTTimes(fetchedBatches.count)) fetchGalleryInfoForImageFiles:anything()
                                                                                          fromSiteURL:self.testArticle.url.wmf_siteURL
                                                                                              success:anything()
                                                                                              failure:anything()];
}

- (void)testErrorHandling {
  NSRange attemptedBatch = [self.controller batchRangeForTargetIndex:0];

  [self.controller fetchBatchContainingIndex:0];

  assertThat(@([self.controller.fetchedIndices containsIndexesInRange:attemptedBatch]),
             describedAs(@"batch range to be optimistically marked as 'fetched'",
                         isTrue(), nil));

  PushExpectation();

  NSError *dummyError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
  [self mockInfoFetcherFailure:dummyError forTitlesInRange:attemptedBatch];

  WaitForExpectations();

  assertThat(@([self.controller.fetchedIndices containsIndexesInRange:attemptedBatch]),
             describedAs(@"batch to be reset after error handling, allowing it to be fetched again",
                         isFalse(), nil));

  [MKTVerify(self.mockDelegate) imageInfoController:self.controller
                                 failedToFetchBatch:attemptedBatch
                                              error:dummyError];
}

#pragma mark - Verifications & Expectations

- (void)verifyInfoFetcherCallForIndexes:(NSIndexSet *)indexes {
  [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    NSRange expectedRange = [self.controller batchRangeForTargetIndex:idx];
    assertThat(@(WMFRangeIsNotFoundOrEmpty(expectedRange)), isFalse());
    [self verifyInfoFetcherCallForRange:expectedRange withSuccess:nil failure:nil];
  }];
}

- (void)verifyInfoFetcherCallForRange:(NSRange)range
                          withSuccess:(id)success
                              failure:(id)failure {
  NSArray *expectedTitles = [self expectedTitlesForRange:range];
  [MKTVerifyCount(self.mockInfoFetcher, MKTTimes(1)) fetchGalleryInfoForImageFiles:expectedTitles
                                                                       fromSiteURL:self.testArticle.url.wmf_siteURL
                                                                           success:success ?: anything()
                                                                           failure:failure ?: anything()];
}

- (NSArray *)expectedTitlesForRange:(NSRange)range {
  return [self.controller.imageFilePageTitles subarrayWithRange:range];
}

- (void)verifySuccessfulFetchesForRanges:(NSArray *)ranges {
  NSUInteger numImages = [ranges count] * self.controller.infoBatchSize;
  NSMutableArray *accumulatedFetchedImageInfos = [NSMutableArray arrayWithCapacity:numImages];

  for (NSValue *boxedRange in ranges) {
    PushExpectation();
    assertThat(@([self.controller hasFetchedAllItems]), isFalse());
    [self fetchRangeSuccessfully:boxedRange.rangeValue
                      fromImages:self.controller.uniqueArticleImages
                 withAccumulator:accumulatedFetchedImageInfos];
  }

  WaitForExpectations();

  assertThat(self.controller.indexedImageInfo.allValues,
             containsItemsInCollectionInAnyOrder(accumulatedFetchedImageInfos));

  assertThat([self.tmpDataStore imageInfoForArticleWithURL:self.testArticle.url],
             containsItemsInCollectionInAnyOrder(accumulatedFetchedImageInfos));

  assertThat(@([self.controller hasFetchedAllItems]), isTrue());

  for (NSValue *boxedRange in ranges) {
    [MKTVerify(self.mockDelegate) imageInfoController:self.controller didFetchBatch:boxedRange.rangeValue];
  }

  assertThat(accumulatedFetchedImageInfos, hasCountOf(self.controller.uniqueArticleImages.count));
}

- (void)fetchRangeSuccessfully:(NSRange)range
                    fromImages:(NSArray *)testImages
               withAccumulator:(NSMutableArray *)accumulatedInfos {
  [self.controller fetchBatchContainingIndex:range.location];

  assertThat(@([self.controller.fetchedIndices containsIndexesInRange:range]),
             describedAs(@"Ranges should be marked as fetched the first time they're requested", isTrue(), nil));

  NSArray *imageInfoForCurrentBatch = [MWKImageInfo mappedFromImages:[testImages subarrayWithRange:range]];
  [accumulatedInfos addObjectsFromArray:imageInfoForCurrentBatch];

  [self mockInfoFetcherSuccess:range];
}

#pragma mark - Delegate Call Forwarding

- (void)imageInfoController:(WMFImageInfoController *)controller failedToFetchBatch:(NSRange)range error:(NSError *)error {
  [self popExpectationAfter:^{
    [self.mockDelegate imageInfoController:controller failedToFetchBatch:range error:error];
  }];
}

- (void)imageInfoController:(WMFImageInfoController *)controller didFetchBatch:(NSRange)range {
  [self popExpectationAfter:^{
    [self.mockDelegate imageInfoController:controller didFetchBatch:range];
  }];
}

#pragma mark - Mocking

- (void)mockInfoFetcherSuccess:(NSRange)range {
  MKTArgumentCaptor *successBlockCaptor = [MKTArgumentCaptor new];
  [self verifyInfoFetcherCallForRange:range withSuccess:[successBlockCaptor capture] failure:nil];
  void (^successBlock)(NSArray *) = [successBlockCaptor value];
  successBlock([MWKImageInfo mappedFromImages:[self.controller.uniqueArticleImages subarrayWithRange:range]]);
}

- (void)mockInfoFetcherFailure:(NSError *)error forTitlesInRange:(NSRange)range {
  MKTArgumentCaptor *errorBlockCaptor = [MKTArgumentCaptor new];
  [self verifyInfoFetcherCallForRange:range withSuccess:nil failure:[errorBlockCaptor capture]];
  void (^errorBlock)(NSError *) = [errorBlockCaptor value];
  errorBlock(error);
}

#pragma mark - Data Generation

- (NSArray *)createAllExpectedBatches {
  NSUInteger numBatches = self.controller.uniqueArticleImages.count / self.controller.infoBatchSize;
  NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:numBatches];
  for (int i = 0; i < numBatches; i++) {
    [ranges addObject:WMFBoxedRangeMake(i * self.controller.infoBatchSize, self.controller.infoBatchSize)];
  }
  return [ranges copy];
}

- (NSArray *)generateSourceURLs:(NSUInteger)count {
  NSMutableArray *names = [NSMutableArray new];
  for (NSUInteger i = 0; i < count; i++) {
    NSString *sourceURL =
        MWKCreateImageURLWithPath([NSString stringWithFormat:@"/foobar/foo%lu.jpg/440px-foo%lu.jpg", (unsigned long)i, (unsigned long)i]);
    [names addObject:sourceURL];
  }
  return [names copy];
}

@end
