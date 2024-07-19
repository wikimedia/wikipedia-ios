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
 *  Used for comparing @c NSDate objects relative to the device's current time zone.
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
 *  @return The number of days between the dates.
 */
- (NSInteger)wmf_daysFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

/**
 *  Used for getting the number of calendar days between dates. For example, if you compare 12 PM on a day to 9 AM on the following day, you would get 1 day between those dates despite the fact that there's less than 24 hours between the dates.
 *
 *  @param fromDate the earlier date - the year on this date can be invalid
 *  @param toDate the later date - this date's year will be used to infer a date for fromDate
 *
 *  @return The number of days between the dates.
 */
- (NSInteger)wmf_daysFromMonthAndDay:(NSDate *)fromDate toDate:(NSDate *)toDate;

/**
 *  Used for getting the number of calendar years, month, days, hours, minutes, and/or seconds between dates.
 *
 *  @param unitFlags the unit flags to request
 *  @param fromDate the earlier date
 *  @param toDate the later date
 *
 *  @return The components between the dates.
 */
- (NSDateComponents *)wmf_components:(NSCalendarUnit)unitFlags fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

@end

@interface NSDate (WMFComparisons)

- (BOOL)wmf_isTodayUTC;
- (BOOL)wmf_UTCDateIsTodayLocal;                         //TimeZone insensitive compare, assumes reciever is UTC date
- (BOOL)wmf_UTCDateIsSameDateAsLocalDate:(NSDate *)date; //TimeZone insensitive compare, assumes reciever is UTC date

- (NSDate *)wmf_midnightUTCDateFromLocalDateByAddingDays:(NSInteger)days;

@property (nonatomic, readonly) NSDate *wmf_midnightUTCDateFromLocalDate;          //Assumes the receiever is a local date, returns midnight UTC on the same day, month, and year.
@property (nonatomic, readonly) NSDate *wmf_midnightUTCDateFromUTCDate;            //Assumes the receiever is a UTC date, returns midnight UTC on the same day, month, and year.
@property (nonatomic, readonly) NSDate *wmf_midnightLocalDateForEquivalentUTCDate; //Assumes the receiever is a local date, returns midnight local time for the same UTC day, month, and year. For example, 10 PM Eastern 1/5/2017 will return midnight eastern 1/6/2017 (since 10 PM eastern on 1/5 is already 1/6 UTC)
@property (nonatomic, readonly) NSDate *wmf_midnightDate;

@end
