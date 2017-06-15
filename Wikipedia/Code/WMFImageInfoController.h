@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class MWKDataStore;
@class MWKImage;
@class MWKImageInfo;
@class MWKImageInfoFetcher;
@class AFHTTPSessionManager;
@protocol MWKImageInfoRequest;

@class WMFImageInfoController;
@protocol WMFImageInfoControllerDelegate <NSObject>

- (void)imageInfoController:(WMFImageInfoController *)controller didFetchBatch:(NSRange)range;

- (void)imageInfoController:(WMFImageInfoController *)controller failedToFetchBatch:(NSRange)range error:(NSError *)error;

@end

@interface WMFImageInfoController : NSObject

@property (nonatomic, weak) id<WMFImageInfoControllerDelegate> delegate;

/// Number of image info titles to request at once.
@property (nonatomic, readonly) NSUInteger infoBatchSize;

/**
 *  Set the array of images for which info will be fetched.
 *
 *  @param uniqueArticleImages The images used to "batch" info requests.
 *  @param title               The title the images are associated with.
 */
- (void)setUniqueArticleImages:(NSArray<MWKImage *> *)uniqueArticleImages forArticleURL:(NSURL *)url;

/**
 *  Reset image & info properties and cancel any fetches.
 */
- (void)reset;

///
/// @name Initialization
///

/// Initialize with @c article, letting the receiver create the default @c fetcher and @c imageFetcher.
- (instancetype)initWithDataStore:(MWKDataStore *)dataStore batchSize:(NSUInteger)batchSize;

/// Designated initializer.
- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                        batchSize:(NSUInteger)batchSize
                      infoFetcher:(MWKImageInfoFetcher *)fetcher NS_DESIGNATED_INITIALIZER;

///
/// @name Fetching
///

/**
 * Fetch the image info batch which contains @c index if it hasn't already been fetched.
 *
 * @return The request to fetch the specified batch, or @c nil if it has already been fetched or the index is
 *         out of bounds.
 */
- (id<MWKImageInfoRequest> __nullable)fetchBatchContainingIndex:(NSInteger)index;

/// Convenience for fetching batches for multiple target indexes at once.
- (NSArray *__nullable)fetchBatchesContainingIndexes:(NSIndexSet *)indexes;

/**
 * Convenience for fetching the specified @c index as well as its neighbor.
 *
 * @param index The index contained by the batch which will be fetched.
 *
 * @param next  The modifier used to fetch another batch. This is equivalent to:
 *              <pre>[imageInfoController fetchBatchContainingIndex:index+next];</pre>
 *
 * Note that this will either result in one fetch (@c index and <code>index + next</code> is in the same batch or
 * two fetches if @c index and <code>index + next</code> are in different batches.
 */
- (NSArray *__nullable)fetchBatchContainingIndex:(NSInteger)index withNthNeighbor:(NSUInteger)next;

///
/// @name Getters
///

/// @return The @c MWKImageInfo object which is associated with @c image, or @c nil if none exists.
- (MWKImageInfo *__nullable)infoForImage:(MWKImage *)image;

/// @return The index of the @c MWKImage associated with @c info, or @c NSNotFound.
- (NSUInteger)indexOfImageAssociatedWithInfo:(MWKImageInfo *)info;

@end

NS_ASSUME_NONNULL_END
