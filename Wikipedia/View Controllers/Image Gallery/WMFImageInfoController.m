//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageInfoController_Private.h"

#import <BlocksKit/BlocksKit.h>
#import "WMFRangeUtils.h"
#import "NSArray+BKIndex.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "NSIndexSet+BKReduce.h"

NS_ASSUME_NONNULL_BEGIN

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFImageInfoControllerLogLevel

static const int LOG_LEVEL_DEF = DDLogLevelDebug;


NSDictionary* WMFIndexImageInfo(NSArray* __nullable imageInfo){
    return [imageInfo bk_index:^id < NSCopying > (MWKImageInfo* info) {
        return info.imageAssociationValue ? : [NSNull null];
    }];
}

@implementation WMFImageInfoController
@synthesize imageInfoFetcher    = _imageInfoFetcher;
@synthesize indexedImageInfo    = _indexedImageInfo;
@synthesize imageFilePageTitles = _imageFilePageTitles;
@synthesize fetchedIndices      = _fetchedIndices;
@synthesize uniqueArticleImages = _uniqueArticleImages;

- (instancetype)initWithArticle:(MWKArticle* __nullable)article batchSize:(NSUInteger)batchSize {
    return [self initWithArticle:article batchSize:batchSize infoFetcher:[[MWKImageInfoFetcher alloc] initWithDelegate:nil]];
}

- (instancetype)initWithArticle:(MWKArticle* __nullable)article
                      batchSize:(NSUInteger)batchSize
                    infoFetcher:(MWKImageInfoFetcher*)fetcher {
    NSAssert(batchSize <= 50, @"Only up to 50 titles can be retrieved at a time.");
    self = [super init];
    if (self) {
        _article          = article;
        _imageInfoFetcher = fetcher;
        _infoBatchSize    = batchSize;
    }
    return self;
}

#pragma mark - Accessors

- (void)setArticle:(MWKArticle* __nullable)article {
    if ([_article isEqualToArticle:article]) {
        return;
    }
    _article = article;

    // reset all lazily-calculated properties and state
    _uniqueArticleImages = nil;
    _imageFilePageTitles = nil;
    _indexedImageInfo    = nil;
    _fetchedIndices      = nil;
}

- (NSArray*)uniqueArticleImages {
    if (!self.article) {
        return @[];
    }
    if (!_uniqueArticleImages) {
        NSArray* uniqueArticleImages = [self.article.images uniqueLargestVariants];

        // reverse article images if current language is RTL
        _uniqueArticleImages = [uniqueArticleImages wmf_reverseArrayIfApplicationIsRTL];;

        NSMutableArray* imageFilePageTitles = [NSMutableArray arrayWithCapacity:_uniqueArticleImages.count];

        // reduce images to only those who have valid canonical filenames
        _uniqueArticleImages =
            [[_uniqueArticleImages bk_reduce:[NSMutableArray arrayWithCapacity:_uniqueArticleImages.count]
                                   withBlock:^id (NSMutableArray* uniqueArticleImages, MWKImage* image) {
            NSAssert(image.canonicalFilename.length,
                     @"Unable to form canonical filename from image: %@",
                     image.sourceURLString);
            if (image.canonicalFilename.length) {
                NSString* filePageTitle = [@"File:" stringByAppendingString:image.canonicalFilename];
                [imageFilePageTitles addObject:filePageTitle];
                [uniqueArticleImages addObject:image];
            }
            return uniqueArticleImages;
        }] copy];

        // strictly evaluate iamgeFilePageTitles to filter out any images don't have a canonicalFilename
        _imageFilePageTitles = [imageFilePageTitles copy];
    }
    return _uniqueArticleImages ? : @[];
}

- (NSDictionary*)indexedImageInfo {
    if (!self.article) {
        return @{};
    }
    if (!_indexedImageInfo) {
        _indexedImageInfo =
            WMFIndexImageInfo([self.dataStore imageInfoForArticle:self.article]) ? : [NSMutableDictionary new];
    }
    return _indexedImageInfo;
}

- (MWKDataStore* __nullable)dataStore {
    return self.article.dataStore;
}

- (NSUInteger)indexOfImageAssociatedWithInfo:(MWKImageInfo*)info {
    return [self.uniqueArticleImages indexOfObjectPassingTest:^BOOL (MWKImage* img, NSUInteger idx, BOOL* stop) {
        if ([img isAssociatedWithInfo:info]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
}

- (NSMutableIndexSet*)fetchedIndices {
    if (!_fetchedIndices) {
        _fetchedIndices =
            [self.indexedImageInfo.allValues bk_reduce:[NSMutableIndexSet new]
                                             withBlock:^id (NSMutableIndexSet* acc, MWKImageInfo* info) {
            NSInteger infoIndex = [self indexOfImageAssociatedWithInfo:info];
            if (infoIndex != NSNotFound) {
                [acc addIndex:infoIndex];
            }
            return acc;
        }];
    }
    return _fetchedIndices ? : [NSMutableIndexSet new];
}

- (BOOL)hasFetchedAllItems {
    return [self.fetchedIndices containsIndexesInRange:NSMakeRange(0, self.uniqueArticleImages.count)];
}

- (MWKImageInfo* __nullable)infoForImage:(MWKImage*)image {
    return self.indexedImageInfo[image.infoAssociationValue];
}

#pragma mark - Public Fetch

- (id<MWKImageInfoRequest> __nullable)fetchBatchContainingIndex:(NSInteger)index {
    return [self fetchBatch:[self batchRangeForTargetIndex:index]];
}

- (NSArray* __nullable)fetchBatchesContainingIndexes:(NSIndexSet*)indexes {
    if (indexes.count == 0 || !self.article) {
        return nil;
    } else {
        return [indexes bk_reduce:[NSMutableArray new]
                        withBlock:^NSMutableArray*(NSMutableArray* acc, NSUInteger index) {
            id<MWKImageInfoRequest> request = [self fetchBatchContainingIndex:index];
            if (request) {
                [acc addObject:request];
            }
            return acc;
        }];
    }
}

- (NSArray* __nullable)fetchBatchContainingIndex:(NSInteger)index withNthNeighbor:(NSUInteger)next {
    NSAssert(next >= 0, @"No reason to call this method with next == 0");
    NSMutableIndexSet* indexes     = [NSMutableIndexSet indexSetWithIndex:index];
    NSUInteger const neighborIndex = index + next;
    if (neighborIndex < self.uniqueArticleImages.count) {
        [indexes addIndex:index + next];
    }
    return [self fetchBatchesContainingIndexes:indexes];
}

#pragma mark - Private Fetch

- (NSRange)batchRangeForTargetIndex:(NSUInteger)index {
    if (!self.article) {
        return WMFRangeMakeNotFound();
    }
    NSParameterAssert(index < self.uniqueArticleImages.count);
    if (index > self.uniqueArticleImages.count) {
        DDLogWarn(@"Attempted to fetch %lu which is beoynd upper bound of %lu",
                  index, self.uniqueArticleImages.count);
        return WMFRangeMakeNotFound();
    }
    NSUInteger const start = floorf(index / (float)self.infoBatchSize) * self.infoBatchSize;
    NSRange const range    = NSMakeRange(start, MIN(self.infoBatchSize, self.uniqueArticleImages.count - start));
    NSParameterAssert(range.location <= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) >= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) <= self.uniqueArticleImages.count);
    NSParameterAssert(!WMFRangeIsNotFoundOrEmpty(range));
    return range;
}

- (id<MWKImageInfoRequest> __nullable)fetchBatch:(NSRange)batch {
    if (!self.article) {
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

    NSArray* titlesToFetch = [self.imageFilePageTitles subarrayWithRange:batch];
    NSParameterAssert(titlesToFetch.count > 0);

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    __weak MWKArticle* currentArticle = self.article;
    __weak __typeof__((self)) weakSelf = self;
    return [self.imageInfoFetcher fetchInfoForPageTitles:titlesToFetch
                                                fromSite:self.article.site
                                                 success:^(NSArray* infoObjects) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        __typeof__((weakSelf)) strSelf = weakSelf;
        if (!strSelf || ![currentArticle isEqualToArticle:strSelf.article]) {
            return;
        }
        NSDictionary* indexedInfo = WMFIndexImageInfo(infoObjects);
        dispatch_async(dispatch_get_main_queue(), ^{
            [strSelf.indexedImageInfo setValuesForKeysWithDictionary:indexedInfo];
            // !!!: we should have already read any pre-existing image info from the data store
            [[strSelf dataStore] saveImageInfo:strSelf.indexedImageInfo.allValues forArticle:strSelf.article];
            [strSelf.delegate imageInfoController:strSelf didFetchBatch:batch];
        });
    }
                                                 failure:^(NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        __typeof__((weakSelf)) strSelf = weakSelf;
        BOOL wasCancelled = [error.domain isEqualToString:NSURLErrorDomain]
                            && error.code == NSURLErrorCancelled;
        if (strSelf) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strSelf.fetchedIndices removeIndexesInRange:batch];
                if (!wasCancelled) {
                    [strSelf.delegate imageInfoController:strSelf failedToFetchBatch:batch error:error];
                }
            });
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
