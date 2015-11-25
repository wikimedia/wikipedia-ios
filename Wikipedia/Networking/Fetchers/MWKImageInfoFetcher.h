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
- (id<MWKImageInfoRequest>)fetchInfoForImageFiles:(NSArray*)imageTitles
                                         fromSite:(MWKSite*)site
                                          success:(void (^)(NSArray* infoObjects))success
                                          failure:(void (^)(NSError* error))failure;

/**
 * Fetch the imageinfo for the images which are preseent on the given pages.
 * @param imageTitles One or more page titles to retrieve images from, and then fetch info for.
 * @param site        A site object for the MW site to target.
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchInfoForImagesFoundOnPages:(NSArray*)pageTitles
                                                 fromSite:(MWKSite*)site
                                         metadataLanguage:(NSString*)metadataLanguage
                                           thumbnailWidth:(NSUInteger)thumbnailWidth
                                                  success:(void (^)(NSArray*))success
                                                  failure:(void (^)(NSError*))failure;

- (void)cancelAllFetches;

@end
