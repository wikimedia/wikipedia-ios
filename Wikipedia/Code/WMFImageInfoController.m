#import "WMFImageInfoController_Private.h"

#import <BlocksKit/BlocksKit.h>
#import "MWKImage+CanonicalFilenames.h"
#import "SessionSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"

NS_ASSUME_NONNULL_BEGIN

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFImageInfoControllerLogLevel

static const int LOG_LEVEL_DEF = DDLogLevelDebug;

NSDictionary *WMFIndexImageInfo(NSArray *__nullable imageInfo) {
    return [imageInfo bk_reduce:[NSMutableDictionary dictionaryWithCapacity:imageInfo.count]
                      withBlock:^NSMutableDictionary *(NSMutableDictionary *indexedInfo, MWKImageInfo *info) {
                          id<NSCopying> key = info.imageAssociationValue;
                          if (key) {
                              indexedInfo[key] = info;
                          }
                          return indexedInfo;
                      }];
}

@implementation WMFImageInfoController
@synthesize imageInfoFetcher = _imageInfoFetcher;
@synthesize indexedImageInfo = _indexedImageInfo;
@synthesize imageFilePageTitles = _imageFilePageTitles;
@synthesize fetchedIndices = _fetchedIndices;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore batchSize:(NSUInteger)batchSize {
    return [self initWithDataStore:dataStore batchSize:batchSize infoFetcher:[[MWKImageInfoFetcher alloc] initWithDelegate:nil]];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                        batchSize:(NSUInteger)batchSize
                      infoFetcher:(MWKImageInfoFetcher *)fetcher {
    NSAssert(batchSize <= 50, @"Only up to 50 titles can be retrieved at a time.");
    NSParameterAssert(dataStore);
    NSParameterAssert(fetcher);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        _imageInfoFetcher = fetcher;
        _infoBatchSize = batchSize;
    }
    return self;
}

#pragma mark - Accessors

- (void)setUniqueArticleImages:(NSArray<MWKImage *> *)uniqueArticleImages forArticleURL:(NSURL *)url {
    if (_uniqueArticleImages == uniqueArticleImages && WMF_EQUAL(self.articleURL, isEqual:, url)) {
        return;
    }

    [self reset];

    self.articleURL = url;
    _uniqueArticleImages = [uniqueArticleImages copy] ?: @[];
}

- (nullable NSArray *)imageFilePageTitles {
    if (!_imageFilePageTitles) {
        // reduce images to only those who have valid canonical filenames
        _imageFilePageTitles = [[MWKImage mapFilenamesFromImages:_uniqueArticleImages] copy];
    }
    return _imageFilePageTitles;
}

- (nullable NSDictionary *)indexedImageInfo {
    if (!_indexedImageInfo) {
        _indexedImageInfo = WMFIndexImageInfo([self.dataStore imageInfoForArticleWithURL:self.articleURL]) ?: [NSMutableDictionary new];
    }
    return _indexedImageInfo;
}

- (NSUInteger)indexOfImageAssociatedWithInfo:(MWKImageInfo *)info {
    return [self.uniqueArticleImages indexOfObjectPassingTest:^BOOL(MWKImage *img, NSUInteger idx, BOOL *stop) {
        if ([img isAssociatedWithInfo:info]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
}

- (nullable NSMutableIndexSet *)fetchedIndices {
    if (!_fetchedIndices) {
        _fetchedIndices =
            [self.indexedImageInfo.allValues bk_reduce:[NSMutableIndexSet new]
                                             withBlock:^id(NSMutableIndexSet *acc, MWKImageInfo *info) {
                                                 NSInteger infoIndex = [self indexOfImageAssociatedWithInfo:info];
                                                 if (infoIndex != NSNotFound) {
                                                     [acc addIndex:infoIndex];
                                                 }
                                                 return acc;
                                             }];
    }
    return _fetchedIndices ?: [NSMutableIndexSet new];
}

- (BOOL)hasFetchedAllItems {
    return [self.fetchedIndices containsIndexesInRange:NSMakeRange(0, self.uniqueArticleImages.count)];
}

- (MWKImageInfo *__nullable)infoForImage:(MWKImage *)image {
    return self.indexedImageInfo[image.infoAssociationValue];
}

#pragma mark - Public Fetch

- (void)reset {
    _uniqueArticleImages = nil;
    _articleURL = nil;
    _imageFilePageTitles = nil;
    _indexedImageInfo = nil;
    _fetchedIndices = nil;
    [self.imageInfoFetcher cancelAllFetches];
}

- (id<MWKImageInfoRequest> __nullable)fetchBatchContainingIndex:(NSInteger)index {
    return [self fetchBatch:[self batchRangeForTargetIndex:index]];
}

- (NSArray *__nullable)fetchBatchesContainingIndexes:(NSIndexSet *)indexes {
    if (indexes.count == 0 || !self.articleURL) {
        return nil;
    } else {
        return [indexes bk_reduce:[NSMutableArray new]
                        withBlock:^NSMutableArray *(NSMutableArray *acc, NSUInteger index) {
                            id<MWKImageInfoRequest> request = [self fetchBatchContainingIndex:index];
                            if (request) {
                                [acc addObject:request];
                            }
                            return acc;
                        }];
    }
}

- (NSArray *__nullable)fetchBatchContainingIndex:(NSInteger)index withNthNeighbor:(NSUInteger)next {
    NSAssert(next >= 0, @"No reason to call this method with next == 0");
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndex:index];
    NSUInteger const neighborIndex = index + next;
    if (neighborIndex < self.uniqueArticleImages.count) {
        [indexes addIndex:index + next];
    }
    return [self fetchBatchesContainingIndexes:indexes];
}

#pragma mark - Private Fetch

- (NSRange)batchRangeForTargetIndex:(NSUInteger)index {
    if (!self.articleURL) {
        return WMFRangeMakeNotFound();
    }
    NSParameterAssert(index < self.uniqueArticleImages.count);
    if (index > self.uniqueArticleImages.count) {
        DDLogWarn(@"Attempted to fetch %lu which is beyond upper bound of %lu",
                  (unsigned long)index, (unsigned long)self.uniqueArticleImages.count);
        return WMFRangeMakeNotFound();
    }
    NSUInteger const start = floorf(index / (float)self.infoBatchSize) * self.infoBatchSize;
    NSRange const range = NSMakeRange(start, MIN(self.infoBatchSize, self.uniqueArticleImages.count - start));
    NSParameterAssert(range.location <= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) >= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) <= self.uniqueArticleImages.count);
    NSParameterAssert(!WMFRangeIsNotFoundOrEmpty(range));
    return range;
}

- (id<MWKImageInfoRequest> __nullable)fetchBatch:(NSRange)batch {
    if (!self.articleURL) {
        return nil;
    }
    NSParameterAssert(!WMFRangeIsNotFoundOrEmpty(batch));
    if (WMFRangeIsNotFoundOrEmpty(batch)) {
        DDLogWarn(@"Attempted to fetch not found or empty range: %@", NSStringFromRange(batch));
        return nil;
    } else if ([self.fetchedIndices containsIndexesInRange:batch]) {
        DDLogDebug(@"Batch %@ has already been fetched.", NSStringFromRange(batch));
        return nil;
    }
    NSParameterAssert(batch.length <= self.infoBatchSize);
    DDLogDebug(@"Fetching batch: %@", NSStringFromRange(batch));

    // optimistically add batch to fetched indices, then remove it if the request fails
    [self.fetchedIndices addIndexesInRange:batch];

    // might have failed to parse some image file titles, filter them out
    NSArray *titlesToFetch = [[self.imageFilePageTitles subarrayWithRange:batch] bk_reject:^BOOL(id obj) {
        return obj == [NSNull null];
    }];

    NSParameterAssert(titlesToFetch.count > 0);

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    NSURL *curentArticleURL = self.articleURL;
    @weakify(self);
    return [self.imageInfoFetcher fetchGalleryInfoForImageFiles:titlesToFetch
        fromSiteURL:self.articleURL.wmf_siteURL
        success:^(NSArray *infoObjects) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            @strongify(self);
            if (!self || ![curentArticleURL isEqual:self.articleURL]) {
                return;
            }
            NSDictionary *indexedInfo = WMFIndexImageInfo(infoObjects);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.indexedImageInfo setValuesForKeysWithDictionary:indexedInfo];
                // !!!: we should have already read any pre-existing image info from the data store
                // HAX: we need to re-save the entire array every time, otherwise info will be "dropped"
                [[self dataStore] saveImageInfo:self.indexedImageInfo.allValues forArticleURL:self.articleURL];
                [self.delegate imageInfoController:self didFetchBatch:batch];
            });
        }
        failure:^(NSError *error) {
            @strongify(self);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            if (self) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.fetchedIndices removeIndexesInRange:batch];
                    if (!([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)) {
                        [self.delegate imageInfoController:self failedToFetchBatch:batch error:error];
                    }
                });
            }
        }];
}

@end

NS_ASSUME_NONNULL_END
