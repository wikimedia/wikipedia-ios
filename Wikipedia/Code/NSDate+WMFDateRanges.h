//
//  NSDate+WMFDateRanges.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WMFDateRanges)

/**
 *  Get an array of @c NSDate objects represnting the days between the receiver and the given date.
 *
 *  Results will always be returned in descending order (latest to earliest).  All dates in the returned array will
 *  have a time based on the later date (i.e. @c self if it is later than @c date, or vice versa).
 *
 *  @param date The other end of the range of dates to create.
 *
 *  @return A range of dates between now and the receiver, ordered in descending order (latest to earliest).
 */
- (NSArray<NSDate*>*)wmf_datesUntilDate:(NSDate*)date;

- (NSArray<NSDate*>*)wmf_datesUntilToday;

@end
