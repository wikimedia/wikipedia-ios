//
//  NSDate+WMFMostReadDate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 *  If the receiver's hour is past 6 (06:00 UTC), the prior day's most read articles should be available.  Otherwise, 
 *  fall back to the day before yesterday.  This is designed to minimize the chance of getting a 404 error due to data 
 *  not being available for the requested day.
 *
 *  @return The day before the receiver if its hour is greater than 6, otherwise two days before.
 */
- (instancetype)wmf_bestMostReadFetchDate;

@end
