//
//  NSDate+WMFPOTDDateRange.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WMFPOTDDateRange)

- (NSArray<NSDate*>*)wmf_datesUntilDate:(NSDate*)date;

/**
 *  @return A range of dates between now and the receiver, ordered in descending order (latest to earliest).
 */
- (NSArray<NSDate*>*)wmf_datesUntilToday;

@end
