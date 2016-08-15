//
//  NSDate+WMFMostReadDate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Time after which pageview API data is most likely to be available.
 *
 *  If the receiver's hour is past this value, the prior day's most read articles should be available.  Otherwise,
 *  fall back to the day before yesterday.  This is designed to minimize the chance of getting a 404 error due to data
 *  not being available for the requested day.
 *
 *  @note
 *  This should be removed if/when feed architecture supports only adding sections after data has been retrieved.
 */
extern NSInteger const WMFPageviewDataAvailabilityThreshold;

@interface NSDate (WMFMostReadDate)

/**
 *  @return The most recent fetch date which is likely to have available data.
 *
 *  @see -wmf_bestMostReadFetchDate
 */
+ (instancetype)wmf_latestMostReadDataWithLikelyAvailableData;

/**
 *  The most recent date, before the receiver, which is likely to have available data for the most read articles.
 *
 *  @note @c NSDate is always in UTC (all times are relative to reference date 2001 Jan 1 0:00:00 UTC)
 *
 *  @return The day before the receiver if it is beyond the pageview data availability threshold, otherwise two days before.
 */
- (instancetype)wmf_bestMostReadFetchDate;

@end
