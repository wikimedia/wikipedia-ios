//
//  NSCalendar+WMFCommonCalendars.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCalendar (WMFCommonCalendars)

/**
 *  UTC Gregorian Calendar
 *
 *  Used for comparing @c NSDate objects regardless of the device's current time zone.  It's important to do date arithmetic
 *  with this calendar since it will avoid issues caused by first (implicitly) converting the specified dates to the
 *  user's time zone, thus changing their components.  For example: comparing a date at UTC 0:00 with another date will
 *  change the "day" calendar unit, making calculations like "is on same day as" return false results.
 *
 *  @return A calendar initialized with the Gregorian calendar identfier and the UTC time zone.
 */
+ (instancetype)wmf_utcGregorianCalendar;

@end
