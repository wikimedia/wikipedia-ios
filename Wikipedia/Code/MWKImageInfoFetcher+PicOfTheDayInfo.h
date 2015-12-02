//
//  MWKImageInfoFetcher+PicOfTheDayInfo.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfoFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKImageInfoFetcher (PicOfTheDayInfo)

/**
 *  Fetch a single @c MWKImageInfo object for the given date's Commons Picture of the Day.
 *
 *  @param date             The date to fetch POTD info for.
 *  @param metadataLanguage The language metadata should be request in. Defaults to current locale's language code if @c nil.
 *
 *  @return A promise resolving to an array containing a single @c MWKImageInfo object.
 */
- (AnyPromise*)fetchPicOfTheDaySectionInfoForDate:(NSDate*)date metadataLanguage:(nullable NSString*)metadataLanguage;

/**
 *  Fetch one @c MWKImageInfo object for each date's Commons Picture of the Day.
 *
 *  @param date             The dates to fetch POTD info for.
 *  @param metadataLanguage The language metadata should be request in. Defaults to current locale's language code if @c nil.
 *
 *  @return A promise resolving to a single @c MWKImageInfo object.
 */
- (AnyPromise*)fetchPicOfTheDayGalleryInfoForDates:(NSArray<NSDate*>*)dates metadataLanguage:(nullable NSString*)metadataLanguage;

@end

NS_ASSUME_NONNULL_END
