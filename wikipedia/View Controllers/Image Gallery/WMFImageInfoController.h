//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKArticle;
@class MWKImage;
@class MWKImageInfo;
@class MWKImageInfoFetcher;
@class AFHTTPRequestOperationManager;
@protocol MWKImageInfoRequest;

@class WMFImageInfoController;
@protocol WMFImageInfoControllerDelegate <NSObject>

- (void)imageInfoController:(WMFImageInfoController*)controller didFetchBatch:(NSRange)range;

- (void)imageInfoController:(WMFImageInfoController*)controller failedToFetchBatch:(NSRange)range error:(NSError*)error;

@end

@interface WMFImageInfoController : NSObject

@property (nonatomic, strong, readonly) MWKArticle* article;

@property (nonatomic, weak) id<WMFImageInfoControllerDelegate> delegate;

/// Number of image info titles to request at once.
@property (nonatomic, readonly) NSUInteger infoBatchSize;

/// Lazily calculated snapshot of the uniqued images in the receiver's @c article.
@property (nonatomic, readonly) NSArray* uniqueArticleImages;

///
/// @name Initialization
///

/// Initialize with @c article, letting the receiver create the default @c fetcher and @c imageFetcher.
- (instancetype)initWithArticle:(MWKArticle*)article batchSize:(NSUInteger)batchSize;

/// Designated initializer.
- (instancetype)initWithArticle:(MWKArticle*)article
                      batchSize:(NSUInteger)batchSize
                    infoFetcher:(MWKImageInfoFetcher*)fetcher;

///
/// @name Fetching
///

/**
 * Fetch the image info batch which contains @c index if it hasn't already been fetched.
 *
 * @return The request to fetch the specified batch, or @c nil if it has already been fetched or the index is
 *         out of bounds.
 */
- (id<MWKImageInfoRequest>)fetchBatchContainingIndex:(NSInteger)index;

/// Convenience for fetching batches for multiple target indexes at once.
- (NSArray*)fetchBatchesContainingIndexes:(NSIndexSet*)indexes;

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
- (NSArray*)fetchBatchContainingIndex:(NSInteger)index withNthNeighbor:(NSUInteger)next;

///
/// @name Getters
///

/// @return The @c MWKImageInfo object which is associated with @c image, or @c nil if none exists.
- (MWKImageInfo*)infoForImage:(MWKImage*)image;

/// @return The index of the @c MWKImage associated with @c info, or @c NSNotFound.
- (NSUInteger)indexOfImageAssociatedWithInfo:(MWKImageInfo*)info;

@end
