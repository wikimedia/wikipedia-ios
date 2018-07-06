#import <WMF/NSDateFormatter+WMFExtensions.h>

static NSString *const WMF_ISO8601_FORMAT = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

@implementation NSDateFormatter (WMFExtensions)

+ (NSDateFormatter *)wmf_iso8601Formatter {
    static NSDateFormatter *iso8601Formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // need to use "en" locale, otherwise the timestamp will fail to parse when the current locale is arabic on iOS 6
        iso8601Formatter = [NSDateFormatter new];
        iso8601Formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        iso8601Formatter.dateFormat = WMF_ISO8601_FORMAT;
        ;
        iso8601Formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return iso8601Formatter;
}

+ (NSISO8601DateFormatter *)wmf_rfc3339LocalTimeZoneFormatter {
    static NSISO8601DateFormatter *wmf_rfc3339LocalTimeZoneFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wmf_rfc3339LocalTimeZoneFormatter = [NSISO8601DateFormatter new];
        wmf_rfc3339LocalTimeZoneFormatter.timeZone = [NSTimeZone localTimeZone];
        wmf_rfc3339LocalTimeZoneFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    });
    return wmf_rfc3339LocalTimeZoneFormatter;
}

+ (NSDateFormatter *)wmf_shortTimeFormatter {
    NSParameterAssert([NSThread isMainThread]);
    static NSDateFormatter *shortTimeFormatter = nil;
    if (!shortTimeFormatter) {
        shortTimeFormatter = [self wmf_shortTimeFormatterWithLocale:[NSLocale currentLocale]];
    }
    return shortTimeFormatter;
}

+ (NSDateFormatter *)wmf_shortTimeFormatterWithLocale:(NSLocale *)locale {
    NSDateFormatter *shortTimeFormatter = [NSDateFormatter new];
    shortTimeFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    shortTimeFormatter.dateStyle = NSDateFormatterNoStyle;
    shortTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    shortTimeFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    shortTimeFormatter.locale = locale;
    return shortTimeFormatter;
}

+ (NSDateFormatter *)wmf_longDateFormatter {
    NSParameterAssert([NSThread isMainThread]);
    static NSDateFormatter *longDateFormatter = nil;
    if (!longDateFormatter) {
        // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [longDateFormatter setDateFormat:WMF_ISO8601_FORMAT];
        longDateFormatter.dateStyle = NSDateFormatterLongStyle;
        longDateFormatter.timeStyle = NSDateFormatterNoStyle;
        longDateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    }
    return longDateFormatter;
}

+ (instancetype)wmf_utcMediumDateFormatterWithoutTime {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[self wmf_mediumDateFormatterWithoutTime] copy];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_mediumDateFormatterWithoutTime {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return _dateFormatter;
}

+ (instancetype)wmf_englishHyphenatedYearMonthDayFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [self wmf_newEnglishYearMonthDayFormatterWithSeparator:@"-"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_englishUTCNonDelimitedYearMonthDayFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [self wmf_newEnglishYearMonthDayFormatter];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_englishUTCNonDelimitedYearMonthDayHourFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [self wmf_newEnglishYearMonthDayHourFormatter];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_englishUTCSlashDelimitedYearMonthDayFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [self wmf_newEnglishYearMonthDayFormatterWithSeparator:@"/"];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_newEnglishYearMonthDayFormatterWithSeparator:(NSString *)separator {
    NSString *quotedSeparator = [@[@"'", separator, @"'"] componentsJoinedByString:@""];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = [@[@"yyyy", @"MM", @"dd"] componentsJoinedByString:quotedSeparator];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    return dateFormatter;
}

+ (instancetype)wmf_newEnglishYearMonthDayFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    return dateFormatter;
}

+ (instancetype)wmf_newEnglishYearMonthDayHourFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddhh";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    return dateFormatter;
}

+ (instancetype)wmf_dayNameMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"EEEEMMMMd"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[self wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] copy];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_monthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"MMMMd"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_utcMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[self wmf_monthNameDayOfMonthNumberDateFormatter] copy];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_shortDayNameShortMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"EEEMMMdd"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_shortMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"MMMd"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[self wmf_shortDayNameShortMonthNameDayOfMonthNumberDateFormatter] copy];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_yearMonthDayZDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'Z'";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_yearMonthDayPathDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy'/'MM'/'dd";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

@end
