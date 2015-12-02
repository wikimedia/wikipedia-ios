//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FetcherBase.h"

@class MWKArticle;
@class MWKSite;
@class AFHTTPRequestOperation;
@class AFHTTPRequestOperationManager;

@protocol MWKImageInfoRequest <NSObject>

- (void)cancel;

@end

@interface MWKImageInfoFetcher : FetcherBase

- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate;

/**
 * Fetch the imageinfo for the given image page titles.
 * @param imageTitles One or more page titles to get imageinfo for (e.g. @c "File:My_Image_Title.jpg).
 * @param site        A site object for the MW site to target.
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchGalleryInfoForImageFiles:(NSArray*)imageTitles
                                                fromSite:(MWKSite*)site
                                                 success:(void (^)(NSArray* infoObjects))success
                                                 failure:(void (^)(NSError* error))failure;

/**
 * Fetch the a subset of the imageinfo for the images which are preseent on the given pages.
 *
 * Used in context where not all image info is needed (e.g. POTD cell in the Home view).
 *
 * @param imageTitles One or more page titles to retrieve images from, and then fetch info for.
 * @param site        A site object for the MW site to target.
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchPartialInfoForImagesOnPages:(NSArray*)pageTitles
                                                   fromSite:(MWKSite*)site
                                           metadataLanguage:(NSString*)metadataLanguage
                                                    success:(void (^)(NSArray*))success
                                                    failure:(void (^)(NSError*))failure;

/**
 * Fetch the imageinfo for the images which are preseent on the given pages.
 *
 * Used to fetch all necessary info for display in the gallery (metadata, artist, license, etc.).
 *
 * @param imageTitles One or more page titles to retrieve images from, and then fetch info for.
 * @param site        A site object for the MW site to target.
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchGalleryInfoForImagesOnPages:(NSArray*)pageTitles
                                                   fromSite:(MWKSite*)site
                                           metadataLanguage:(NSString*)metadataLanguage
                                                    success:(void (^)(NSArray*))success
                                                    failure:(void (^)(NSError*))failure;

- (void)cancelAllFetches;

@end
