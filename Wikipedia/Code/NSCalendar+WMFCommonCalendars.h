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

/**
 *  UTC Gregorian Calendar
 *
 *  Used for comparing @c NSDate objects relative to the the device's current time zone.
 *
 *  @return A calendar initialized with the Gregorian calendar identfier and the device's current time zone.
 */
+ (instancetype)wmf_gregorianCalendar;

/**
 *  Used for getting the number of calendar days between dates. For example, if you compare 12 PM on a day to 9 AM on the following day, you would get 1 day between those dates despite the fact that there's less than 24 hours between the dates.
 *
 *  @param fromDate the earlier date
 *  @param toDate the later date
 *
 *  @return A calendar initialized with the Gregorian calendar identfier and the device's current time zone.
 */
- (NSInteger)wmf_daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

@end

@interface NSDate (WMFComparisons)

- (BOOL)wmf_isTodayUTC;
- (BOOL)wmf_UTCDateIsTodayLocal; //TimeZone insensitive compare, assumes reciever is UTC date
- (BOOL)wmf_UTCDateIsSameDateAsLocalDate:(NSDate *)date; //TimeZone insensitive compare, assumes reciever is UTC date
@property (nonatomic, readonly) NSDate *wmf_midnightUTCDate; //Assumes the receiever is a local date, returns midnight UTC on the same day, month, and year.
@property (nonatomic, readonly) NSDate *wmf_midnightDate;
@end
