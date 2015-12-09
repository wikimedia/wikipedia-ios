//
//  WMFModalPOTDGalleryDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSArrayDataSource.h>
#import "WMFModalImageGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const WMFDefaultNumberOfPOTDDates;

/**
 *  Data source of the Picture of the Day gallery.
 *
 *  Fetches additional metadata & high-resolution images from Wikimedia Commons' picture of the day.
 */
@interface WMFModalPOTDGalleryDataSource : SSArrayDataSource
    <WMFModalImageGalleryDataSource>

/**
 *  Create a data source for displaying picture of the day starting with a specific date.
 *
 *  @note Currently hard-coded to today since the app doesn't support having multiple POTD in the Home view.
 *        Once this is supported, we will need to pass one or more info objects (and dates) and specify the info to
 *        display (similar to <code>-[WMFModalArticleImageGallery setVisibleImage:animated:]</code>).
 *
 *  @param info Info for an image which will be displayed when the gallery is first presented while it fetches more
 *              metadata and the other days.
 *
 *  @param date The date that @c info is associated with.
 *
 *  @return A new data source which is populated with today's and the previous 15 days' picture of the day.
 */
- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date;

@end

NS_ASSUME_NONNULL_END
