@import WMF;
#import "WMFLogFormatter.h"

static NSString *cachedApplicationName;

@implementation WMFLogFormatter

// NOTE: The libraries print a lot of junk to the logs. Filter on `#L` to only see log lines added by the Wikipedia app.

#if DEBUG
// To print timestamps in logs in a non-release build, change following line to `YES`.
BOOL const shouldShowFullDateInLog = NO;
#else
BOOL const shouldShowFullDateInLog = YES;
#endif

NSDateFormatter *_dateFormatter;

+ (void)initialize {
    if (self == [WMFLogFormatter class]) {
        cachedApplicationName = [[NSBundle mainBundle] wmf_bundleName];

        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *level = @"";
    switch (logMessage->_flag) {
        case DDLogFlagVerbose:
            level = @"🗣️";
            break;
        case DDLogFlagDebug:
            level = @"💬";
            break;
        case DDLogFlagInfo:
            level = @"ℹ️";
            break;
        case DDLogFlagWarning:
            level = @"⚠️";
            break;
        case DDLogFlagError:
            level = @"🚨";
            break;
        default:
            break;
    }

    NSString *date = @"";
    if (shouldShowFullDateInLog) {
        date = [self stringFromDate:logMessage->_timestamp];
    } else {
        date = [_dateFormatter stringFromDate:logMessage->_timestamp];
    }
    return [NSString stringWithFormat:@"%@ %@: %@ [%@#L%lu]",
                                      level,
                                      date,
                                      logMessage -> _message,
                                      logMessage -> _fileName,
                                      (unsigned long)logMessage -> _line];
}

@end
