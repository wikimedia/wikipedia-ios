#import "MWKImageInfoFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKImageInfoFetcher (PicOfTheDayInfo)

/**
 *  Fetch a single @c MWKImageInfo object for the given date's Commons Picture of the Day.
 *
 *  @param date             The date to fetch POTD info for.
 *  @param metadataLanguage The language metadata should be request in. Defaults to current locale's language code if @c nil.
 *  @param success          On success resolves to an array containing a single @c MWKImageInfo object.
 *
 */
- (void)fetchPicOfTheDaySectionInfoForDate:(NSDate *)date metadataLanguage:(nullable NSString *)metadataLanguage failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

/**
 *  Fetch one @c MWKImageInfo object for the given date's Commons Picture of the Day.
 *
 *  The info must be fetched individually, since there's no reliable way to correlate the responses with their matching
 *  date.
 *
 *  @param date             The dates to fetch POTD info for.
 *  @param metadataLanguage The language metadata should be request in. Defaults to current locale's language code if @c nil.
 *
 */
- (void)fetchPicOfTheDayGalleryInfoForDate:(NSDate *)date metadataLanguage:(nullable NSString *)metadataLanguage failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

@end

NS_ASSUME_NONNULL_END
