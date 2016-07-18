//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FetcherBase.h"

@class MWKArticle;
@class NSURLSessionDataTask;
@class AFHTTPSessionManager;

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
                                           fromDomainURL:(NSURL*)domainURL
                                                 success:(void (^)(NSArray* infoObjects))success
                                                 failure:(void (^)(NSError* error))failure;

- (AnyPromise*)fetchGalleryInfoForImage:(NSString*)canonicalPageTitle fromDomainURL:(NSURL*)domainURL
;

/**
 * Fetch @c MWKImageInfo populated with only the data needed for display in the home view.
 *
 * Used in context where only the image URL and description are needed.
 *
 * @param pageTitles       One or more page titles to retrieve images from, and then fetch info for.
 * @param site             A site object for the MW site to target.
 * @param metadataLanguage The langauge to attempt to retrieve image metadata in. Falls back to English if the specified
 *                         langauge isn't available. Defaults to current locale's language if @c nil.
 *
 * @return A promise which resolves to the @c MWKImageInfo containing info the images found on the specified pages.
 */
- (AnyPromise*)fetchPartialInfoForImagesOnPages:(NSArray*)pageTitles
                                  fromDomainURL:(NSURL*)domainURL
                               metadataLanguage:(NSString*)metadataLanguage;

/**
 * Fetch @c MWKImageInfo populated with enough suitable for display in a modal gallery.
 *
 * Used in contexts where image URL, description, artist, etc. are needed.
 *
 * @param pageTitles       One or more page titles to retrieve images from, and then fetch info for.
 * @param site             A site object for the MW site to target.
 * @param metadataLanguage The langauge to attempt to retrieve image metadata in. Falls back to English if the specified
 *                         langauge isn't available. Defaults to the current locale's language if @c nil.
 *
 * @return A promise which resolves to the @c MWKImageInfo containing info the images found on the specified pages.
 */
- (AnyPromise*)fetchGalleryInfoForImagesOnPages:(NSArray*)pageTitles
                                  fromDomainURL:(NSURL*)domainURL
                               metadataLanguage:(NSString*)metadataLanguage;

- (void)cancelAllFetches;

@end
