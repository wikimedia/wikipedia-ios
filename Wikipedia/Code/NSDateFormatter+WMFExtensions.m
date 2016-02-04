
#import "NSDateFormatter+WMFExtensions.h"

static NSString* const WMF_ISO8601_FORMAT = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

@implementation NSDateFormatter (WMFExtensions)

+ (NSDateFormatter*)wmf_iso8601Formatter {
    static NSDateFormatter* iso8601Formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // need to use "en" locale, otherwise the timestamp will fail to parse when the current locale is arabic on iOS 6
        iso8601Formatter = [NSDateFormatter new];
        iso8601Formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        iso8601Formatter.dateFormat = WMF_ISO8601_FORMAT;;
        iso8601Formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return iso8601Formatter;
}

+ (NSDateFormatter*)wmf_shortTimeFormatter {
    NSParameterAssert([NSThread isMainThread]);
    static NSDateFormatter* shortTimeFormatter = nil;
    if (!shortTimeFormatter) {
        shortTimeFormatter = [self wmf_shortTimeFormatterWithLocale:[NSLocale currentLocale]];
    }
    return shortTimeFormatter;
}

+ (NSDateFormatter*)wmf_shortTimeFormatterWithLocale:(NSLocale*)locale {
    NSDateFormatter* shortTimeFormatter = [NSDateFormatter new];
    shortTimeFormatter.timeZone          = [NSTimeZone timeZoneWithName:@"UTC"];
    shortTimeFormatter.dateStyle         = NSDateFormatterNoStyle;
    shortTimeFormatter.timeStyle         = NSDateFormatterShortStyle;
    shortTimeFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    shortTimeFormatter.locale            = locale;
    return shortTimeFormatter;
}

+ (NSDateFormatter*)wmf_longDateFormatter {
    NSParameterAssert([NSThread isMainThread]);
    static NSDateFormatter* longDateFormatter = nil;
    if (!longDateFormatter) {
        // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [longDateFormatter setDateFormat:WMF_ISO8601_FORMAT];
        longDateFormatter.dateStyle         = NSDateFormatterLongStyle;
        longDateFormatter.timeStyle         = NSDateFormatterNoStyle;
        longDateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
    }
    return longDateFormatter;
}

+ (instancetype)wmf_mediumDateFormatterWithoutTime {
    static NSDateFormatter* _dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return _dateFormatter;
}

+ (instancetype)wmf_englishHyphenatedYearMonthDayFormatter {
    static NSDateFormatter* _dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'";
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    });
    return _dateFormatter;
}

+ (instancetype)wmf_dayNameMonthNameDayOfMonthNumberDateFormatter {
    static NSDateFormatter* _dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocalizedDateFormatFromTemplate:@"EEEEMMMMdd"];
    });
    return _dateFormatter;
}

@end
