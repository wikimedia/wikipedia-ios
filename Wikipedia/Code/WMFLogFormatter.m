@import WMF;
#import "WMFLogFormatter.h"

static NSString *cachedApplicationName;

@implementation WMFLogFormatter

// NOTE: The libraries print a lot of junk to the logs. Filter on `(From:` to only see log lines added by the Wikipedia app.

#if DEBUG
// To print timestamps in logs in a non-release build, change following line to `YES`.
BOOL const shouldShowDateInLog = NO;
#else
BOOL const shouldShowDateInLog = YES;
#endif

+ (void)initialize {
    if (self == [WMFLogFormatter class]) {
        cachedApplicationName = [[NSBundle mainBundle] wmf_bundleName];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *level = @"";
    switch (logMessage->_flag) {
        case DDLogFlagVerbose:
            level = @"🗣️ VERBOSE";
            break;
        case DDLogFlagDebug:
            level = @"💬 DEBUG";
            break;
        case DDLogFlagInfo:
            level = @"ℹ️  INFO";
            break;
        case DDLogFlagWarning:
            level = @"⚠️  WARN";
            break;
        case DDLogFlagError:
            level = @"🚨 ERROR";
            break;
        default:
            break;
    }

    if (shouldShowDateInLog) {
        return [NSString stringWithFormat:@"[%@] %@: %@ [%@#L%lu]",
                                          level,
                                          [self stringFromDate:logMessage->_timestamp],
                                          logMessage -> _message,
                                          logMessage -> _fileName,
                                          (unsigned long)logMessage -> _line];
    } else {
        return [NSString stringWithFormat:@"%@: %@ [%@#L%lu]",
                                          level,
                                          logMessage->_message,
                                          logMessage->_fileName,
                                          (unsigned long)logMessage->_line];
    }
}

@end
