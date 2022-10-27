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
    static dispatch_once_t onceToken;
    static NSDateFormatter *shortTimeFormatter = nil;
    dispatch_once(&onceToken, ^{
        shortTimeFormatter = [self wmf_shortTimeFormatterWithLocale:[NSLocale currentLocale]];
    });
    return shortTimeFormatter;
}

+ (NSDateFormatter *)wmf_customVoiceOverTimeFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter = nil;
    dispatch_once(&onceToken, ^{
        formatter = [self wmf_customVoiceOverTimeFormatterWithLocale:[NSLocale currentLocale]];
    });
    return formatter;
}

+ (NSDateFormatter *)wmf_shortDateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *shortDateFormatter = nil;
    dispatch_once(&onceToken, ^{
        shortDateFormatter = [NSDateFormatter new];
        shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
        shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
        shortDateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    });
    return shortDateFormatter;
}

+ (NSDateFormatter *)wmf_24hshortTimeFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *shortTimeFormatter = nil;
    dispatch_once(&onceToken, ^{
        shortTimeFormatter = [self wmf_shortTimeFormatterWithLocale:[NSLocale currentLocale]];
        shortTimeFormatter.dateFormat = @"HH:mm";
    });
    return shortTimeFormatter;
}

+ (NSDateFormatter *)wmf_24hshortTimeFormatterWithUTCTimeZone {
    static dispatch_once_t onceToken;
    static NSDateFormatter *shortTimeFormatter = nil;
    dispatch_once(&onceToken, ^{
        shortTimeFormatter = [self wmf_shortTimeFormatterWithLocale:[NSLocale currentLocale]];
        shortTimeFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        shortTimeFormatter.dateFormat = @"HH:mm zzz";
    });
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

+ (NSDateFormatter *)wmf_customVoiceOverTimeFormatterWithLocale:(NSLocale *)locale {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeZone = [NSTimeZone localTimeZone];
    formatter.dateStyle = NSDateFormatterLongStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.formatterBehavior = NSDateFormatterBehavior10_4;
    formatter.locale = locale;
    return formatter;
}

+ (NSDateFormatter *)wmf_longDateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *longDateFormatter = nil;
    dispatch_once(&onceToken, ^{
        // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [longDateFormatter setDateFormat:WMF_ISO8601_FORMAT];
        longDateFormatter.dateStyle = NSDateFormatterLongStyle;
        longDateFormatter.timeStyle = NSDateFormatterNoStyle;
        longDateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    });
    return longDateFormatter;
}

+ (instancetype)wmf_localCustomShortDateFormatterWithTimeForLocale:(NSLocale *)locale {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setLocale: locale];
    [formatter setLocalizedDateFormatFromTemplate:@"hh:mm a, dd.MM.yyyy"];
    return formatter;
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

+ (instancetype)wmf_monthNameDayOfMonthNumberYearDateFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"MMMM d, yyyy"];
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

+ (instancetype)wmf_yearFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_monthFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"MM";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_dayFormatter {
    static NSDateFormatter *_dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"dd";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

@end
