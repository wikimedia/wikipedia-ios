#import <Foundation/Foundation.h>

@interface NSDateFormatter (WMFExtensions)

/**
 * Formatter which can be used to parse timestamps from the mediawiki API.
 *
 * @note It is safe to call this method from any thread.
 *
 * @return Singleton @c NSDateFormatter for transcoding WMF timestamps.
 */
+ (NSDateFormatter *)wmf_iso8601Formatter;

+ (NSISO8601DateFormatter *)wmf_rfc3339LocalTimeZoneFormatter;

/**
 * Formatter which can be used to present a short time string for a given date.
 *
 * @warning Do not attempt to parse raw timestamps from the mediawiki API using this method. Use the unstyled
 *          @c +wmf_iso8601Formatter method instead.
 *
 * @note    This method is not thread safe, as it is intended to only be used by code which presents text to the user.
 *
 * @see +[NSDateFormatter wmf_iso8601Formatter]
 *
 * @return Singleton @c NSDateFormatter for displaying times to the user.
 */
+ (NSDateFormatter *)wmf_shortTimeFormatter;

+ (NSDateFormatter *)wmf_customVoiceOverTimeFormatter;

+ (NSDateFormatter *)wmf_shortDateFormatter;

+ (NSDateFormatter *)wmf_24hshortTimeFormatter;

+ (NSDateFormatter *)wmf_24hshortTimeFormatterWithUTCTimeZone;

/**
 * Create an short-style time formatter with the given locale.
 * @warning This method is exposed for testing only, use @c +wmf_shortTimeFormatter instead.
 */
+ (NSDateFormatter *)wmf_shortTimeFormatterWithLocale:(NSLocale *)locale;

/**
 * Create a long style date formatter. Sample: "April 24, 2015".
 */
+ (NSDateFormatter *)wmf_longDateFormatter;

+ (instancetype)wmf_localCustomShortDateFormatterWithTimeForLocale:(NSLocale *)locale;

+ (instancetype)wmf_mediumDateFormatterWithoutTime;

+ (instancetype)wmf_utcMediumDateFormatterWithoutTime;

+ (instancetype)wmf_englishHyphenatedYearMonthDayFormatter;

+ (instancetype)wmf_englishUTCNonDelimitedYearMonthDayFormatter;

+ (instancetype)wmf_englishUTCNonDelimitedYearMonthDayHourFormatter;

+ (instancetype)wmf_dayNameMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_utcMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_englishUTCSlashDelimitedYearMonthDayFormatter;

+ (instancetype)wmf_shortDayNameShortMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_shortMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter;

+ (instancetype)wmf_yearMonthDayZDateFormatter;

+ (instancetype)wmf_monthNameDayOfMonthNumberYearDateFormatter;

+ (instancetype)wmf_yearFormatter;  // 1905
+ (instancetype)wmf_monthFormatter; // 05
+ (instancetype)wmf_dayFormatter;   // 09

@end
