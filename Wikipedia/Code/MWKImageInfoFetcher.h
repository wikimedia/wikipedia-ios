#import <Foundation/Foundation.h>
#import <WMF/WMFLegacyFetcher.h>
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFPreferredLanguageInfoProvider.h>

NS_ASSUME_NONNULL_BEGIN

@class NSURLSessionDataTask;
@class MWKDataStore;

@protocol MWKImageInfoRequest <NSObject>

- (void)cancel;

@end

@interface MWKImageInfoFetcher : WMFLegacyFetcher

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

/**
 * Fetch the imageinfo for the given image page titles.
 * @param imageTitles One or more page titles to get imageinfo for (e.g. @c "File:My_Image_Title.jpg).
 * @param site        A site object for the MW site to target.
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchGalleryInfoForImageFiles:(NSArray *)imageTitles
                                             fromSiteURL:(NSURL *)siteURL
                                                 success:(void (^)(NSArray *infoObjects))success
                                                 failure:(void (^)(NSError *error))failure;

- (void)fetchGalleryInfoForImage:(NSString *)canonicalPageTitle fromSiteURL:(NSURL *)siteURL failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

/**
 * Fetch @c MWKImageInfo populated with enough suitable for display in a modal gallery.
 *
 * Used in contexts where image URL, description, artist, etc. are needed.
 *
 * @param pageTitles       One or more page titles to retrieve images from, and then fetch info for.
 * @param site             A site object for the MW site to target.
 * @param metadataLanguage The language to attempt to retrieve image metadata in. Falls back to English if the specified
 *                         language isn't available. Defaults to the current locale's language if @c nil.
 *
 * @param failure is passed an error on failure
 * @param success is passed @c MWKImageInfo containing info the images found on the specified pages.
 */

- (void)fetchGalleryInfoForImagesOnPages:(NSArray *)pageTitles
                             fromSiteURL:(NSURL *)siteURL
                        metadataLanguage:(NSString *)metadataLanguage
                                 failure:(WMFErrorHandler)failure
                                 success:(WMFSuccessIdHandler)success;

- (void)fetchImageInfoForCommonsFiles:(NSArray *)filenames
                              failure:(WMFErrorHandler)failure
                              success:(WMFSuccessIdHandler)success;

- (nullable NSURL *)galleryInfoURLForImageTitles: (NSArray *)imageTitles fromSiteURL: (NSURL *)siteURL;

/**
 * Fetch the raw imageinfo API response for a batch of image page titles.
 *
 * Unlike the other fetch methods this hands back the undigested response, so a caller
 * can split it into one cached entry per title. That is what lets the offline download
 * make one request per batch rather than one per image.
 *
 * Uses the same query parameters as @c galleryInfoURLForImageTitles:fromSiteURL:, so
 * each page in the response carries exactly what a single-title request would have
 * returned for that title.
 *
 * @param imageTitles One or more page titles, at most 50 (the API's limit).
 */
- (nullable NSURLSessionTask *)fetchBatchedGalleryInfoJSONForImageTitles:(NSArray<NSString *> *)imageTitles
                                                             fromSiteURL:(NSURL *)siteURL
                                                                 success:(void (^)(NSDictionary<NSString *, id> *result, NSHTTPURLResponse *_Nullable response))success
                                                                 failure:(void (^)(NSError *error))failure
    NS_SWIFT_NAME(fetchBatchedGalleryInfoJSON(forImageTitles:fromSiteURL:success:failure:));

- (nullable NSURLRequest *)urlRequestForFromURL: (NSURL *)url;

@property (weak, nonatomic) id<WMFPreferredLanguageInfoProvider> preferredLanguageDelegate;

@end

NS_ASSUME_NONNULL_END
